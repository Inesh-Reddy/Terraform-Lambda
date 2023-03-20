import boto3
from pprint import pprint
import os
import threading

def lambda_handler(event, context):
    message = 'Hello {} !'.format(event['key1'])

    regions = ['ap-south-1', 'us-east-1']

    def delete_unused_volumes(volume_Id_del):
        response = client.delete_volume(VolumeId=volume_Id_del)

    for i in regions:
        volumes_to_delete = list()
        print('------ region : ', str(i), '---------')
        client = boto3.client('ec2', region_name=str(i))
        volume_detail = client.describe_volumes()
        if volume_detail['ResponseMetadata']['HTTPStatusCode'] == 200:
            for each_volume in volume_detail['Volumes']:
                print("Working for volume with volume_id: ", each_volume['VolumeId'])
                print("State of volume: ", each_volume['State'])
                print("Attachment state length: ", len(each_volume['Attachments']))
                print("Volume Attachments: ", each_volume['Attachments'])
                print("--------------------------------------------")
                if len(each_volume['Attachments']) == 0 and each_volume['State'] == 'available':
                    volumes_to_delete.append(each_volume['VolumeId'])
        print('Volumes to be deleted in ', str(i),':')
        pprint(volumes_to_delete)
        print('-------------------------------------------')
        if len(volumes_to_delete) == 0 :
            print("No unattached EBS volumes")
            continue
        # threads = []
        # for volume in volumes_to_delete:
        #     t = threading.Thread(target=delete_unused_volumes(volume))
        #     threads.append(t)
        #     t.start()
        # waiter = client.get_waiter('volume_deleted')
        # try:
        #     waiter.wait(
        #         VolumeIds=volumes_to_delete,
        #     )
        #     print("Successfully deleted all volumes")
        # except Exception as e:
        #     print("Error in process with error being: " + str(e))

    return {
        'message' : message
    }