VIRTHOST=$(hostname -f)
NODE_IMAGE=http://download-node-02.eng.bos.redhat.com/brewroot/packages/rhel-guest-image/7.6/210/images/rhel-guest-image-7.6-210.x86_64.qcow2
CONTAINER_REGISTRY=registry-proxy.engineering.redhat.com

infrared virsh -o cleanup.yml \
    --host-address $VIRTHOST \
    --host-key ~/.ssh/id_rsa \
    --cleanup yes && \
\
infrared virsh \
    -o provision.yml \
    --topology-nodes undercloud:1,controller:1,compute:1 \
    --host-address $VIRTHOST \
    --host-key ~/.ssh/id_rsa \
    --image-url $NODE_IMAGE \
    --host-memory-overcommit True \
    --disk-pool /home/stack/pool \
    -e override.controller.cpu=2 \
    -e override.controller.memory=8192 \
    -e override.undercloud.cpu=4 \
    -e override.undercloud.memory=16384 && \
\
infrared tripleo-undercloud -o install.yml \
    -o undercloud-install.yml \
    --mirror "tlv" \
    --version 13 \
    --build passed_phase1 \
    --director-build latest && \
\
infrared tripleo-undercloud \
   -o images_settings.yml \
   --images-task rpm \
   --build passed_phase1 \
   --images-update no && \
\
infrared tripleo-overcloud \
    -o overcloud-install.yml \
    --version 13 \
    --deployment-files virt \
    --overcloud-debug yes \
    --network-backend vxlan \
    --network-protocol ipv4 \
    --storage-backend lvm \
    --storage-external no \
    --overcloud-ssl no \
    --tls-everywhere no \
    --network-dvr false \
    --network-lbaas false \
    --vbmc-force true \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --public-network yes \
    --public-subnet default_subnet \
    --ntp-server clock.redhat.com \
    --containers yes \
    --registry-mirror $CONTAINER_REGISTRY \
    --registry-undercloud-skip no
