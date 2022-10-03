VIRTHOST=$(hostname -f)
NODE_IMAGE=http://download.eng.bos.redhat.com/brewroot/packages/rhel-guest-image/8.2/220/images/rhel-guest-image-8.2-220.x86_64.qcow2
CONTAINER_REGISTRY=registry-proxy.engineering.redhat.com
infrared virsh -o cleanup.yml \
    --host-address $VIRTHOST \
    --host-key ~/.ssh/id_rsa \
    --cleanup yes && \
\
infrared virsh -o provision.yml \
    --topology-nodes undercloud:1,controller:1,compute:1 \
    --host-address $VIRTHOST \
    --host-key ~/.ssh/id_rsa \
    --image-url $NODE_IMAGE \
    --host-memory-overcommit True \
    --disk-pool /home/stack/pool \
    -e override.controller.cpu=2 \
    -e override.controller.memory=8192 \
    -e override.undercloud.cpu=4 \
    -e override.undercloud.memory=12288 \
    -e override.undercloud.disks.disk1.size=150G && \
\
infrared tripleo-undercloud -o install.yml \
    -o undercloud-install.yml \
    --mirror "tlv" \
    --version 16 \
    --build passed_phase2 \
    --tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt \
    --config-options DEFAULT.undercloud_timezone=UTC \
    --director-build latest && \
\
infrared tripleo-undercloud \
    -o images_settings.yml \
    --images-task rpm \
    --build passed_phase2 \
    --images-update no && \
\
infrared tripleo-overcloud \
    -o overcloud-install.yml \
    --version 16 \
    --deployment-files virt \
    --overcloud-debug yes \
    --network-backend geneve \
    --network-protocol ipv4 \
    --storage-external no \
    --overcloud-ssl no \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --containers yes \
    --registry-mirror $CONTAINER_REGISTRY \
    --registry-undercloud-skip no && \
\
infrared cloud-config --deployment-files virt \
    --tasks create_external_network,forward_overcloud_dashboard
