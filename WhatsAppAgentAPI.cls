/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-08-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class WhatsAppAgentAPI {
   
    // Get Access Token from Custom Metadata
    public static String getAccessToken() {
        Meta_Config__mdt config = [SELECT Access_Token__c FROM Meta_Config__mdt LIMIT 1];
        return config.Access_Token__c;
    }

    @InvocableMethod(label='Send WhatsApp Message' description='Sends a WhatsApp message using Contact ID')
    public static List<String> sendMessage(List<MessageInput> inputs) {
        List<String> responses = new List<String>();
        Set<Id> contactIds = new Set<Id>();

        // Collect all Contact IDs
        for (MessageInput input : inputs) {
            if (String.isNotBlank(input.contactId)) {
                contactIds.add(input.contactId);
            }
        }

        // Query contacts and ensure uniqueness
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        for (Contact c : [SELECT Id, Phone FROM Contact WHERE Id IN :contactIds]) {
            if (contactMap.containsKey(c.Id)) {
                responses.add('❌ Duplicate contact found for ID: ' + c.Id);
                continue;
            }
            contactMap.put(c.Id, c);
        }

        // Send messages only to valid contacts
        for (MessageInput input : inputs) {
            if (!contactMap.containsKey(input.contactId)) {
                responses.add('❌ No contact found for ID: ' + input.contactId);
                continue;
            }

            Contact contact = contactMap.get(input.contactId);
            if (String.isNotBlank(contact.Phone)) {
                responses.add(sendWhatsAppTemplateMessage(contact.Phone));
            } else {
                responses.add('❌ No phone number found for Contact ID: ' + input.contactId);
            }
        }

        return responses;
    }

    public static String sendWhatsAppTemplateMessage(String recipientNumber) {
        try {
            if (String.isEmpty(recipientNumber)) {
                return '❌ No phone number provided!';
            }

            String phoneNumberId = '659040530616540'; // Replace with your WhatsApp Business Phone ID
            String endpoint = 'https://graph.facebook.com/v22.0/' + phoneNumberId + '/messages';

            // JSON Payload
            Map<String, Object> payload = new Map<String, Object>{
                'messaging_product' => 'whatsapp',
                'to' => recipientNumber,
                'type' => 'template',
                'template' => new Map<String, Object>{
                    'name' => 'hello_world',
                    'language' => new Map<String, String>{ 'code' => 'en_US' }
                }
            };

            String accessToken = getAccessToken();
            // HTTP Request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setBody(JSON.serialize(payload));

            // Callout Execution
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            return '✅ Message Sent Successfully!';
        } else {
            return '❌ Failed to send message!';
        }
        } catch (Exception e) {
            return '❌ Error sending WhatsApp message: ' + e.getMessage();
        }
    }

    // Wrapper class for Flow input
    public class MessageInput {
        @InvocableVariable(required=true)
        public String contactId; // Passing Contact ID instead of Phone Number
    }
    // new line added
   
}