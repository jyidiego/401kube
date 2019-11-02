// import sns = require('@aws-cdk/aws-sns');
// import subs = require('@aws-cdk/aws-sns-subscriptions');
// import sqs = require('@aws-cdk/aws-sqs');
import cdk = require('@aws-cdk/core');
import eks = require('@aws-cdk/aws-eks');
import { Vpc, SubnetType, InstanceType, SecurityGroup } from '@aws-cdk/aws-ec2';
import iam = require('@aws-cdk/aws-iam')
import cloud9 = require('@aws-cdk/aws-cloud9')

export class EksStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // const queue = new sqs.Queue(this, 'EksQueue', {
      // visibilityTimeout: cdk.Duration.seconds(300)
    // });

    // const topic = new sns.Topic(this, 'EksTopic');

    // topic.addSubscription(new subs.SqsSubscription(queue));


    const vpc = new Vpc(this, 'VPC', {
      maxAzs: 3,
      cidr: "10.10.0.0/16",
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Private-Worker-Nodes',
          subnetType: SubnetType.PRIVATE,
        },
        {
          cidrMask: 24,
          name: 'Public-LBs-NATs',
          subnetType: SubnetType.PUBLIC
        }
      ]
    });


    const clusterAdmin = new iam.Role(this, 'AdminRole', {
      // assumedBy: new iam.AccountRootPrincipal(),
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        { managedPolicyArn: 'arn:aws:iam::aws:policy/AdministratorAccess' }
      ]
    });
    

    const instanceProfileClusterAdmin = new iam.CfnInstanceProfile(this, 'instanceProfileClusterAdmin', {
        instanceProfileName: 'instanceProfileClusterAdmin',
        roles: [
          clusterAdmin.roleName
        ]}
    )
    
    const eksControlPlaneSG = new SecurityGroup(this, 'eksControlPlaneSG', {
      vpc,
      description: 'Allow 443 access to eks masters',
      allowAllOutbound: true   // Can be set to false
    });

 
    const cluster = new eks.Cluster(this, 'fsi405-eks', {
      defaultCapacity: 3,
      defaultCapacityInstance: new InstanceType('t3.medium'),
      vpc: vpc,
      vpcSubnets: [ { 
        onePerAz: true,
        subnetType: SubnetType.PRIVATE
      } ],
      outputClusterName: true,
      mastersRole: clusterAdmin,
      kubectlEnabled: true,
      securityGroup: eksControlPlaneSG
    });


    const eksConsole = new cloud9.CfnEnvironmentEC2(this, 'eksConsole', {
      instanceType: 't2.small',
      description: 'eks management',
      name: 'eksConsole',
      repositories: [
        {
          pathComponent: '/401kube',
          repositoryUrl: 'https://github.com/jyidiego/401kube.git'
        }
      ],
      // Get a list of all public subnetIds in the VPC and pick the first one
      subnetId: vpc.selectSubnets( { onePerAz: true, subnetType: SubnetType.PUBLIC}).subnetIds[0],
      ownerArn: 'arn:aws:iam::657690568281:user/awsdemo001'
    });
    
    
    
  }
}
