FROM public.ecr.aws/spacelift/runner-terraform:latest

WORKDIR /tmp

# Temporarily elevating permissions
USER root

RUN curl -O -L https://github.com/mrolla/terraform-provider-circleci/releases/download/v0.3.0/terraform-provider-circleci-linux-amd64 \
  && mv terraform-provider-circleci-linux-amd64 /bin/terraform-provider-circleci \
  && chmod +x /bin/terraform-provider-circleci

# Back to the restricted "spacelift" user
USER spacelift
