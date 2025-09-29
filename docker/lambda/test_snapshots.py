import unittest
from unittest.mock import patch, MagicMock
from snapshot_cleaner import is_snapshot_in_use

class TestSnapshotCleaner(unittest.TestCase):

    @patch('snapshot_cleaner.ec2_client')
    def test_snapshot_in_use_with_instance(self, mock_ec2):
        # Mock describe_instances to include the snapshot
        mock_ec2.describe_instances.return_value = {
            'Reservations': [
                {
                    'Instances': [
                        {'BlockDeviceMappings': [{'Ebs': {'SnapshotId': 'snap-123'}}]}
                    ]
                }
            ]
        }
        # Mock describe_images to return empty list
        mock_ec2.describe_images.return_value = {'Images': []}

        self.assertTrue(is_snapshot_in_use('snap-123'))

    @patch('snapshot_cleaner.ec2_client')
    def test_snapshot_not_in_use(self, mock_ec2):
        # Mock describe_instances to have no snapshots
        mock_ec2.describe_instances.return_value = {'Reservations': [{'Instances': [{}]}]}
        # Mock describe_images to have no snapshots
        mock_ec2.describe_images.return_value = {'Images': [{'BlockDeviceMappings': [{}]}]}

        self.assertFalse(is_snapshot_in_use('snap-456'))

if __name__ == '__main__':
    unittest.main()
