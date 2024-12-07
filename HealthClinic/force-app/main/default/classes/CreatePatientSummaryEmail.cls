public with sharing class CreatePatientSummaryEmail {
    @InvocableMethod(label='Visit informations'
      description='Summarize all infos about the last visit'
      CapabilityType='PromptTemplateType://einstein_gpt__salesEmail')
    
      public static List<Response> generateVisitSummary(List<Request> requests) {
        // validate the expected number of requests as an input
        if (requests.size() != 1)
            throw new ListException('The requests list must contain one entry only');
        Contact c = requests[0].Recipient;

        ClinicalEncounter lastVisitID = [  //get last visit id
            SELECT Name
            FROM ClinicalEncounter
            WHERE PatientId = : c.AccountId
            ORDER BY StartDate DESC
            LIMIT 1
        ];

        List<HealthCondition> conditions = [  //get informations about last visit
            SELECT Name, ProblemDefinition.Name, ProblemDefinition.Description, Severity, DiagnosticStatus, ClinicalEncounter.StartDate, ClinicalEncounter.EndDate, ClinicalEncounter.Reason__c
            FROM HealthCondition
            WHERE ClinicalEncounter.Name = :lastVisitID.Name
        ];

        List<MedicationStatement> medications = new List<MedicationStatement>();

        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
   
        output.Prompt = 'Use the following infos:';
        
        output.Prompt += '\n Visit informations: ';
        
        for (HealthCondition h : conditions) {
            
            output.Prompt += 'Health condition: \n';
            
            output.Prompt += h.ProblemDefinition.Name +' '+ h.ProblemDefinition.Description + ' '+ h.Severity +' '+ h.DiagnosticStatus +' '+ h.ClinicalEncounter.StartDate +' '+ h.ClinicalEncounter.EndDate +' '+ h.ClinicalEncounter.Reason__c +'\n';

            output.Prompt += 'Relative medications: \n';
            
            medications = [
                SELECT Medication.Name, Dosage__c, Status, StartDateTime, EndDateTime
                FROM MedicationStatement
                WHERE Health_Condition__r.Name = :h.Name
            ];

            for (MedicationStatement s : medications) {
                output.Prompt += s.Medication.Name + ' '+ s.Dosage__c + ' '+ s.Status + ' '+ s.StartDateTime + ' '+s.EndDateTime  +'\n';
            }
        }

        ClinicalEncounter doctorInfo = [
            SELECT Doctor__r.ProviderType, Doctor__r.Account.FirstName, Doctor__r.Account.LastName, Doctor__r.Account.PersonEmail, Doctor__r.Account.PersonMobilePhone
            FROM ClinicalEncounter
            WHERE Name = : lastVisitID.Name
        ];

        output.Prompt += 'Doctor informations: \n';
        output.Prompt += 'Facility: Health Clinic \n'+'Name: '+doctorInfo.Doctor__r.Account.FirstName + ' '+ doctorInfo.Doctor__r.Account.LastName + '\n Title: '+ doctorInfo.Doctor__r.ProviderType + '\n Email: '+ doctorInfo.Doctor__r.Account.PersonEmail + '\n Phone number: '+ doctorInfo.Doctor__r.Account.PersonMobilePhone;

        return responses;
      }

      public class Request {
            @InvocableVariable(required=true)
            public User Sender;
            @InvocableVariable(required=true)
            public Contact Recipient;
      }

      public class Response {
          @InvocableVariable
          public String Prompt;
      }
}