import assert from "node:assert/strict";
import test from "node:test";
import { buildEnvelope, canonicalJson, payloadCommitment } from "../src/index.js";

test("builds signed event envelope", () => {
  const event = buildEnvelope(
    {
      Event_Id__c: "evt_forwarder_test",
      Event_Type__c: "project.registered",
      Schema_Version__c: "1.0.0",
      Object_Type__c: "project",
      Object_Id__c: "project-forwarder-test",
      Occurred_At__c: "2026-08-04T18:00:00Z",
      Payload__c: {
        project_id: "project-forwarder-test",
        project_name: "Forwarder Test",
        producer_id: "producer-forwarder-test",
        country_code: "AU",
        monitoring_period_start: "2026-07-01",
        monitoring_period_end: "2026-12-31",
        current_status: "registered"
      }
    },
    {
      ATHIAN_INTEGRATION_SOURCE: "athian_salesforce_production",
      ATHIAN_INTEGRATION_SECRET: "test-secret"
    }
  );

  assert.equal(event.source, "athian_salesforce_production");
  assert.match(event.integrity.payload_digest, /^sha256:/);
  assert.match(event.integrity.signature, /^v1=/);
  assert.equal(event.integrity.payload_digest, payloadCommitment(canonicalJson(event)));
});
