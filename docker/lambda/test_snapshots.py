import unittest
from snapshot_cleaner import is_snapshot_in_use
from unittest.mock import MagicMock

class TestSnapshotCleaner(unittest.TestCase):
    def test_snapshot_in_use_with_instance(self):
        ec2_client = MagicMock()
        ec2_client.describe_instances.return_value = {
            'Reservations': [{'Instances': [{'BlockDeviceMappings': [{'Ebs': {'SnapshotId': 'snap-123'}}]}]}]
        }
        self.assertTrue(is_snapshot_in_use('snap-123'))

    def test_snapshot_not_in_use(self):
        ec2_client = MagicMock()
        ec2_client.describe_instances.return_value = {'Reservations': [{'Instances': [{}]}]}
        ec2_client.describe_images.return_value = {'Images': [{'BlockDeviceMappings': [{}]}]}
        self.assertFalse(is_snapshot_in_use('snap-456'))

if __name__ == '__main__':
    unittest.main()