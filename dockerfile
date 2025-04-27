### BASE
FROM almalinux:9.5-minimal
    #https://repo.almalinux.org/almalinux/9/isos/x86_64/

### ENV
ENV TERRAFORM_VERSION=1.7.4 \
    #https://releases.hashicorp.com/terraform/
    ANSIBLE_VERSION=8.7.0 \
    #ansible core 2.15
    #https://docs.ansible.com/ansible/latest/roadmap/ansible_roadmap_index.html
    DOCKERCLI_VERSION=1:25.0.3-1.el9 \
    #https://download.docker.com/linux/centos/9/x86_64/stable/Packages/
    KUBECTL_VERSION=v1.29.1 \
    #https://dl.k8s.io/release/stable.txt
    #https://github.com/kubernetes/kubectl/tags
    AWSCLI_VERSION=2.17.49 \
    #https://github.com/aws/aws-cli
    SAM_VERSION=v1.123.0 \
    #https://github.com/aws/aws-sam-cli
    ECSCLI_VERSION=v1.21.0 \
    #https://github.com/aws/amazon-ecs-cli
    EKSCTL_VERSION=v0.171.0
    #https://github.com/eksctl-io/eksctl

### ARG
ARG BUILDARCH
ARG AWSCLIARCH
ARG SAMCLIARCH

### tools
RUN microdnf update -y && \
    microdnf install -y epel-release yum-utils wget sudo which tar zip unzip gzip bind-utils iputils pip git jq tree vi diffutils glibc-locale-source && \
    microdnf clean all && \
    rm -rf /var/cache/yum/* && \
    rm -rf /tmp/*

### TimeZone & LANG
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8

### Terraform
RUN curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip -d /usr/local/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    tflint --version

### Ansible
RUN python -m pip install ansible==${ANSIBLE_VERSION} && \
    /bin/rm -rf /usr/local/lib/python3.9/site-packages/ansible_collections/fortinet

### Docker & Kubernetes
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    microdnf -y install dnf-plugins-core docker-ce-cli-${DOCKERCLI_VERSION} && \
    curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BUILDARCH}/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm ./get_helm.sh && \
    microdnf clean all && \
    rm -rf /var/cache/yum/* && \
    rm -rf /tmp/*

### AWS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLIARCH}-${AWSCLI_VERSION}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm awscliv2.zip && \
    rm -rf ./aws && \
    sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-${BUILDARCH}-${ECSCLI_VERSION} && \
    sudo chmod +x /usr/local/bin/ecs-cli && \
    curl -sLO "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${BUILDARCH}.tar.gz" && \
    tar -xzf eksctl_Linux_${BUILDARCH}.tar.gz -C /tmp && \
    rm eksctl_Linux_${BUILDARCH}.tar.gz &&\
    mv /tmp/eksctl /usr/local/bin

### Cloudformation tools
RUN pip install cfn-lint yq && \
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/aws-cloudformation/cloudformation-guard/main/install-guard.sh | sh && \
cp /root/.guard/3/cfn-guard-v3-*-ubuntu-latest/cfn-guard /usr/local/bin/cfn-guard && \
cfn-guard --version

### SAM CLI
RUN wget https://github.com/aws/aws-sam-cli/releases/download/${SAM_VERSION}/aws-sam-cli-linux-${SAMCLIARCH}.zip && \
    unzip aws-sam-cli-linux-${SAMCLIARCH}.zip -d sam-installation && \
    sudo ./sam-installation/install && \
    rm -rf aws-sam-cli-linux-${SAMCLIARCH}.zip sam-installation && \
    sam --version

### act
RUN curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash && \
mv bin/act /usr/local/bin/act && \
act --version

#rootlessコンテナ devuserでの実行
RUN /usr/sbin/groupadd -r devgroup && \
    /usr/sbin/useradd -r -g devgroup -m devuser && \
    mkdir /work && \
    chown devuser:devgroup /work && \
    echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER devuser
VOLUME /work
WORKDIR /work

ENTRYPOINT ["tail", "-f", "/dev/null"]
