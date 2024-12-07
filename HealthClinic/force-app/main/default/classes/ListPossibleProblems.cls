public with sharing class ListPossibleProblems {
    @InvocableMethod(
      // Matches the API Name of the template
      CapabilityType='FlexTemplate://ListPossibleProblems3'
    )
    public static List<Response> getProblems(List<Request> requests) {
        Request input = requests[0];    //input: Health Condition -> Symptom

        List<ProblemDefinition> candidates = [
             SELECT Name, Description
             FROM ProblemDefinition
             WHERE Symptoms__c = :input.hc.Symptoms__c
        ];

        List<MedicationStatement> medications = new List<MedicationStatement>();

        Account patient = [
            SELECT Age__c,Weight__c
            FROM Account
            WHERE Id = :input.hc.PatientId
        ];

        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);

        output.Prompt += 'Make a bullet list containing the following problems with their description:';
        
        output.Prompt += '\nProblems: ';

        if (candidates.size() == 0) {
            output.Prompt += 'none';
        }

        for (ProblemDefinition p : candidates) {
            output.Prompt += p.Name + ' ' + p.Description + '\n';
        }
        
        output.Prompt += 'Suggested medications for this situation: \n';
        medications = [
            SELECT Medication.Name, Medication.AdultDosagePerMg__c, Medication.KidDosagePerMg__c
            FROM MedicationStatement
            WHERE Health_Condition__r.Symptoms__c=:input.hc.Symptoms__c
        ];

        if (medications.size() == 0) {
            output.Prompt += 'none';
        }

        for (MedicationStatement s : medications) {
            output.Prompt += s.Medication.Name + ' \n Suggested dosage: ';

            if (patient.Age__c <= 18){
                output.Prompt += patient.Weight__c * s.Medication.KidDosagePerMg__c;
            }else{
                output.Prompt += patient.Weight__c * s.Medication.AdultDosagePerMg__c;
            }
            output.Prompt += ' mg \n';
            
        }

        output.Prompt += '\n';

        return responses;
    }
 
    // Type and API Name of all variables must match the template
    public class Request {
        @InvocableVariable(required=true)
        public HealthCondition hc;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;   //IMPORTANT: output must always be 'Prompt'
    }
}