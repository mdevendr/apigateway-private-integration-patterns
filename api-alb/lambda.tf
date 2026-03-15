resource "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    filename = "lambda_function.py"
    content  = <<PY
import json


def _normalise_event(event):
    headers = {str(k).lower(): v for k, v in (event.get("headers") or {}).items()}

    if event.get("version") == "2.0":
        return {
            "source": "apigw-direct-lambda",
            "method": (((event.get("requestContext") or {}).get("http") or {}).get("method")),
            "path": event.get("rawPath"),
            "queryStringParameters": event.get("queryStringParameters"),
            "headers": headers,
            "requestContext": event.get("requestContext"),
            "eventVersion": "2.0"
        }

    if ((event.get("requestContext") or {}).get("elb")) is not None:
        return {
            "source": "vpclink-alb-lambda",
            "method": event.get("httpMethod"),
            "path": event.get("path"),
            "queryStringParameters": event.get("queryStringParameters"),
            "headers": headers,
            "requestContext": event.get("requestContext"),
            "eventVersion": "alb"
        }

    return {
        "source": "unknown",
        "method": event.get("httpMethod"),
        "path": event.get("path"),
        "queryStringParameters": event.get("queryStringParameters"),
        "headers": headers,
        "requestContext": event.get("requestContext"),
        "eventVersion": event.get("version")
    }


def handler(event, context):
    normalised = _normalise_event(event)
    response_body = {
        "message": "hello from shared lambda test backend",
        "source": normalised["source"],
        "method": normalised["method"],
        "path": normalised["path"],
        "queryStringParameters": normalised["queryStringParameters"],
        "headers": {
            "host": normalised["headers"].get("host"),
            "x-forwarded-for": normalised["headers"].get("x-forwarded-for"),
            "x-forwarded-proto": normalised["headers"].get("x-forwarded-proto"),
            "x-amzn-trace-id": normalised["headers"].get("x-amzn-trace-id"),
            "user-agent": normalised["headers"].get("user-agent"),
            "authorization": normalised["headers"].get("authorization")
        },
        "requestContext": normalised["requestContext"],
        "eventVersion": normalised["eventVersion"]
    }

    response = {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {
            "content-type": "application/json"
        },
        "body": json.dumps(response_body)
    }

    if normalised["source"] == "vpclink-alb-lambda":
        response["statusDescription"] = "200 OK"

    return response
PY
  }
}

resource "aws_lambda_function" "backend" {
  function_name    = "${local.name}-backend"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "lambda_function.handler"
  filename         = archive_file.lambda_zip.output_path
  source_code_hash = archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}