#!/usr/bin/python3

import json
import logging
import time
from datetime import datetime
from typing import List, Dict
from pathlib import Path

import backoff
import boto3
import click
import pandas as pd
from pandas.io.parsers import TextFileReader

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def load_csv_into_iterator(path: Path, chunksize: int) -> TextFileReader:
    """Load a CSV file into an iterator that yields chunks of data."""
    
    return pd.read_csv(filepath_or_buffer=path, chunksize=chunksize)

def convert_datetime_to_iso(date_str: str) -> str:
    """Convert a datetime string to ISO format."""
    
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S %Z')
        return dt.isoformat(sep=' ')
    except ValueError:
        logging.error(f"Invalid date format: {date_str}")
        return date_str

def convert_batch_records(chunk: pd.DataFrame) -> List[Dict[str, str]]:
    """Convert a chunk of CSV data into a list of dictionaries."""
    
    records = []
    for _, row in chunk.iterrows():
        record = row.to_dict()

        if 'event_time' in record:
            record["event_time"] = convert_datetime_to_iso(record["event_time"])
        
        for key, value in record.items():
            if pd.isna(value):
                record[key] = None
        record["event_type"] = record.get("event_type", "unknown")
        records.append(record)

    return records

class FirehoseClient():
    """A client for AWS Firehose."""

    def __init__(self, stream_name: str, aws_region: str):
        self.stream_name = stream_name
        self.aws_region = aws_region
        self.client = boto3.client('firehose', region_name=self.aws_region)

    @backoff.on_exception(
        backoff.expo, Exception, max_tries=5, jitter=backoff.full_jitter
    )
    def put_record_batch(self, records: List[Dict[str, str]]) -> None:
        """Put a batch of records into the Firehose stream."""
        try:
            response = self.client.put_record_batch(
                DeliveryStreamName=self.stream_name,
                Records=[{'Data': json.dumps(record).encode('utf-8')} for record in records]
            )
            self._log_batch_response(response, len(records))
        except Exception as e:
                logger.info(f"Failed to send batch of {len(records)} records. Error: {e}")

    def _log_batch_response(self, response: dict, batch_size: int):
        """Log the batch response from Firehose."""

        if response.get("FailedPutCount", 0) > 0:
            logger.error(
                f'Failed to send {response["FailedPutCount"]} records in batch of {batch_size}'
            )
        else:
            logger.info(f"Successfully sent batch of {batch_size} records")


@click.command()
@click.option('--path', type=click.Path(exists=True, dir_okay=False, path_type=Path), required=True, help='Path to the CSV file.')
@click.option('--chunksize', type=int, default=1000, help='Number of rows per chunk to process.')
@click.option('--stream_name', type=str, required=True, help='Name of the Firehose stream to send data to.')
@click.option('--aws_region', type=str, required=True, help='AWS region for Firehose client.')
def main(path: Path, chunksize: int, stream_name: str, aws_region: str):
    """Main function to load a CSV file in chunks and process each chunk."""
    
    logger.info(f'Starting to process the CSV file at {path} with chunksize {chunksize}.')
    firehose_client = FirehoseClient(stream_name, aws_region)
    try:
        csv_iterator = load_csv_into_iterator(path, chunksize)
        for n,chunk in enumerate(csv_iterator):
            records = convert_batch_records(chunk)
            firehose_client.put_record_batch(records)
            logger.info(f'Processed {len(records)} records from the chunk.')
            time.sleep(60)  # Simulate some processing time
    except Exception as e:
        logger.error(f'An error occurred: {e}')
    

if __name__ == '__main__':
    main()