FROM public.ecr.aws/lambda/python:3.12

COPY lambda/requirements.txt ./
RUN pip install -r requirements.txt

COPY lambda/snapshot_cleaner.py ./
COPY lambda/test_snapshots.py ./

CMD ["snapshot_cleaner.lambda_handler"]