### Architecture Note

This example demonstrates the pattern:
```bash
API Gateway → VPC Link → NLB → ALB → Lambda
```

This pattern is included only for comparison with an existing design. For modern API Gateway HTTP API private integrations, a simpler architecture is usually preferred:
```bash
API Gateway → VPC Link → ALB → backend service
```
Adding an NLB in front of the ALB introduces:

- an additional network hop
- extra operational complexity
- higher cost and latency
- no functional benefit for this scenario

Therefore, the NLB layer is unnecessary in this demo architecture.

The Lambda backend is used purely as a lightweight test target to validate connectivity and routing. In real-world deployments, the ALB would typically route traffic to application services (for example EKS services behind an ingress controller).

This folder exists only to illustrate the architectural difference between:
```bash
Option A (Legacy / Existing)
API GW → VPC Link → NLB → ALB → Service

Option B (Recommended)
API GW → VPC Link → ALB → Service


API Gateway → VPC Link → ALB

- `/{proxy+}` via **API Gateway HTTP API -> VPC Link -> internal NLB -> internal ALB -> Lambda**
- `/direct/{proxy+}` via **API Gateway HTTP API -> Lambda direct integration**
```
## What this proves

- API Gateway route matching
- VPC Link forwarding through NLB and ALB
- Direct Lambda integration from the same API Gateway
- Header, path, and auth-header visibility for both routes
- A clean side-by-side comparison between the two patterns

## Prerequisites

- Terraform 1.6+
- AWS CLI already authenticated
- Permissions for VPC, ELBv2, Lambda, IAM, CloudWatch Logs, and API Gateway v2

## Deploy

```bash
cd api-nlb-alb
terraform init
terraform apply
```

## Test

Get the invoke URL:

```bash
terraform output -raw api_invoke_url
```

### 1 Test the VPC Link path

Root path:

```bash
curl -i \
  "$(terraform output -raw api_invoke_url)/"
```

Deeper path:

```bash
curl -i \
  "$(terraform output -raw api_invoke_url)/orders/123?debug=true"
```

Expected response marker:

```json
"source": "vpclink-nlb-alb-lambda"
```

### 2 Test the direct Lambda path

Direct root path:

```bash
curl -i \
  "$(terraform output -raw api_invoke_url)/direct"
```

Direct deeper path:

```bash
curl -i \
  "$(terraform output -raw api_invoke_url)/direct/orders/123?debug=true"
```

Expected response marker:

```json
"source": "apigw-direct-lambda"
```

## Direct ALB check

The ALB is internal, so test from inside the VPC only.

```bash
curl -i \
  "http://$(terraform output -raw alb_dns_name)/orders/123?debug=true"
```

## Direct NLB check

The NLB is internal, so test from inside the VPC only.

```bash
curl -i \
  "http://$(terraform output -raw nlb_dns_name)/orders/123?debug=true"
```

## Temporary auth testing notes

This stack intentionally creates the API without auth so you can first validate pathing and connectivity.

After the path works, you can add:

- JWT authorizer
- Lambda authorizer
- custom domain
- access policies

That helps isolate routing problems from authentication problems.

## Useful troubleshooting

Check API Gateway logs:

```bash
aws logs tail \
  "/aws/apigateway/apigw-vpclink-lab-http-api" \
  --follow \
  --region eu-west-2
```

Check Lambda logs:

```bash
aws logs tail \
  "/aws/lambda/apigw-vpclink-lab-backend" \
  --follow \
  --region eu-west-2
```

Describe NLB target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names apigw-vpclink-lab-alb-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region eu-west-2) \
  --region eu-west-2
```

## Destroy

```bash
terraform destroy
```

## Notes

- The stack uses one HTTP API with two route patterns.
- `/` and `/{proxy+}` use the VPC Link integration.
- `/direct` and `/direct/{proxy+}` use direct Lambda integration.
- The shared Lambda returns a `source` field so you can see which path invoked it.
- The Lambda is not placed in a VPC because the ALB invokes Lambda directly.
