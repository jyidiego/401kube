#!/usr/bin/env node
import cdk = require('@aws-cdk/core');
import { EksStack } from '../lib/eks-stack';

const app = new cdk.App();
new EksStack(app, 'EksStack', {env: { region: 'us-east-2'}});