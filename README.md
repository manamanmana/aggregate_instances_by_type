# aggregate_instances_by_type
Aggregate EC2 instance information group by instance-type, platform and tenancy on each account

## Preparation
This program uses aws-cli, so you first need to prepare standard credentiol and profile like `~/.aws/credentials` and `~/.aws/config`.
Example:

```
$ cat ~/.aws/credentials
[default]
# Main Account: 123456789012
aws_access_key_id = ABCDEFGHIJKLMNOPQRST
aws_secret_access_key = abcdefghijklmnopqrstuvwxwzABCDEFGHIJKLMN

$ cat ~/.aws/config
[default]
output = json
region = us-east-1

[profile accountA]
role_arn = arn:aws:iam::111111111111:role/accountA_Admin
source_profile = default
region = us-east-1

[profile accountB]
role_arn = arn:aws:iam::222222222222:role/accountB_Admin
source_profile = default
region = us-east-1

[profile accountC]
role_arn = arn:aws:iam::333333333333:role/accountC_Admin
source_profile = default
region = us-east-1
```

## Execution
### Aggregate by account (mode: -m account)

Example:

```
# Fields: Region, Instance Type, Platform, Tenancy, Count
$ echo "accountA" | bash aggregate_instances_by_type.sh -m account
sa-east-1,c4.large,None,default,10
sa-east-1,m3.medium,None,default,9
sa-east-1,m4.large,None,default,1
sa-east-1,t2.medium,None,default,3
sa-east-1,t2.micro,None,default,9
sa-east-1,t2.small,None,default,3
```

### Aggregate by region (mode: -m region)

Example:

```
$ cat profile.list
default
accountA
accountB
accountC

# Fields: Region, Instance Type, Platform, Tenancy, Count
$ cat profile.list | bash aggregate_instances_by_type.sh -m region
ap-northeast-1,t2.micro,None,default,2
ap-northeast-1,t2.nano,None,default,3
ap-northeast-1,t2.small,None,default,1

ap-southeast-1,t2.large,None,default,1

eu-west-1,t2.large,None,default,1
eu-west-1,t2.micro,None,default,4
eu-west-1,t2.nano,None,default,3

sa-east-1,c3.2xlarge,None,default,6
sa-east-1,c4.large,None,default,10
sa-east-1,m3.medium,None,default,9
sa-east-1,m4.large,None,default,3
sa-east-1,m4.xlarge,None,default,4
sa-east-1,t2.large,None,default,2
sa-east-1,t2.medium,None,default,38
sa-east-1,t2.micro,None,default,52
sa-east-1,t2.nano,None,default,1
sa-east-1,t2.small,None,default,30

us-east-1,c4.2xlarge,None,default,4
us-east-1,c4.large,None,default,6
us-east-1,m3.medium,None,default,3
us-east-1,m4.large,None,default,1
us-east-1,m4.xlarge,None,default,3
us-east-1,t1.micro,None,default,1
us-east-1,t2.large,None,default,3
us-east-1,t2.medium,None,default,20
us-east-1,t2.medium,windows,default,3
us-east-1,t2.micro,None,default,33
us-east-1,t2.nano,None,default,5
us-east-1,t2.small,None,default,25
```


