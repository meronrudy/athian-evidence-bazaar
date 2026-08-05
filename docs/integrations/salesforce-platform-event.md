# Salesforce Platform Event Bridge

Preferred upstream path:

```text
Athian_Evidence_Event__e
```

Suggested fields:

- `Event_Id__c`
- `Event_Type__c`
- `Schema_Version__c`
- `Object_Type__c`
- `Object_Id__c`
- `Occurred_At__c`
- `Payload__c`
- `Payload_Digest__c`
- `Signature__c`

Salesforce declares the material business event. It does not need to understand
receipt schemas, bundle manifests, country adapters, or the Rust verifier.

Forward the Platform Event to Rails with either Apex callouts or an AWS Lambda
connected to the existing Salesforce/AWS infrastructure.
