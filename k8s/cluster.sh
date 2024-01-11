# Variables
CLUSTER_NAME=team-eks-cluster
REGION=us-east-2
NODE_NAME=Linux-nodes
KEY_NAME=docker-nexus

# Set AWS credentials before script execution

aws sts get-caller-identity >> /dev/null
if [ $? -eq 0 ]
then
 echo "Credentials tested, proceeding with the cluster creation."
 OUTPUT=$(eksctl get cluster --region $REGION)
  if [ "$OUTPUT" == "No clusters found" ]
  then
    echo "$OUTPUT... Creating cluster(s)"
    # Creation of EKS cluster
    eksctl create cluster \
    --name $CLUSTER_NAME \
    --version 1.27 \
    --region $REGION \
    --nodegroup-name $NODE_NAME \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 2 \
    --node-type t3.micro \
    --node-volume-size 8 \
    --ssh-access \
    --ssh-public-key $KEY_NAME \
    --managed
    if [ $? -eq 0 ]
    then
      echo "Cluster Setup Completed with eksctl command."
    else
      echo "Cluster Setup Failed while running eksctl command."
    fi
  else
    echo "Cluster already exists. Proceeding with deployment"
  fi
else
  echo "Please run aws configure & set right credentials."
  echo "Cluster setup failed."
fi
