
.DEFAULT_GOAL := help

credentials-file = pocs-service-account.json
image-definition-file = custom-image.json 

gcp-project = pocs-369513
gcp-zone = europe-west4-a
gcp-machine-type= e2-micro
gcp-instance-name = instance-1
gcp-service-account = 281699279307-compute@developer.gserviceaccount.com
gcp-image = gcp-lb-image

help:
	@echo 'Available commands:'
	@echo -e 'gcp-auth \t\t - \t Authenticates with GCP'

###################################################################################
# GCP
###################################################################################
gcp: gcp-auth gcp-project

gcp-auth:
	gcloud auth activate-service-account --key-file $(credentials-file)

gcp-project:
	 gcloud config set project $(gcp-project) --quiet
	
gcp-vm-create:
	gcloud compute instances create  $(gcp-instance-name) --service-account=$(gcp-service-account) \
	--project=$(gcp-project) --zone=$(gcp-zone) --machine-type=$(gcp-machine-type) \
	--network-interface=network-tier=PREMIUM,subnet=default \
	--provisioning-model=STANDARD --maintenance-policy=MIGRATE \
	--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
	--create-disk=auto-delete=yes,boot=yes,device-name=$(gcp-instance-name),image=projects/$(gcp-project)/global/images/$(gcp-image),mode=rw,size=20,type=projects/$(gcp-project)/zones/$(gcp-zone)/diskTypes/pd-balanced \
	--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

gcp-vm-delete:
	gcloud compute instances delete $(gcp-instance-name) --zone=$(gcp-zone) --quiet

###################################################################################
# PACKER
###################################################################################
packer: packer-validate packer-build

packer-validate:
	packer validate $(image-definition-file)

packer-build:
	packer build -force $(image-definition-file)


###################################################################################
# MICROSERVICE
###################################################################################
docker: docker-build docker-push

docker-auth:
	gcloud auth configure-docker --quiet

docker-build:
	docker build -f ./src/products-rest-api/dockerfile ./src/products-rest-api -t "gcr.io/$(gcp-project)/products-rest-api"

docker-push:
	docker push gcr.io/$(gcp-project)/products-rest-api

