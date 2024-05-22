# tfe_fdo_on_docker_in_external_services_mode_gcp.py

from diagrams import Cluster, Diagram
from diagrams.aws.general import Client
from diagrams.gcp.network import DNS
from diagrams.gcp.compute import ComputeEngine
from diagrams.gcp.database import SQL
from diagrams.gcp.storage import Storage


with Diagram("TFE FDO External Services on GCP", show=False, direction="TB"):
    
    client = Client("Client")
    
    with Cluster("AWS"):
        dns = DNS("DNS")
        with Cluster("VPC"):
            with Cluster("Public Subnet"):
                tfe_instance = ComputeEngine("TFE instance")
            
            with Cluster("Private Subnet"):
                sql = SQL("PostgreSQL")

        storage = Storage("Cloud Storage")

    client >> dns
    dns >> tfe_instance
    tfe_instance >> sql
    tfe_instance >> storage