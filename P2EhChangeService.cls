public with sharing class P2EhChangeService {

    public List<P2EwService.ServiceError> errorList;

    public Case cse { get; set; }
    public Case caseInsertion { get; set; }
    
    public Contract contr {get;set;}
                        
    public P2EhChangeService (){
        errorList = new List<P2EwService.ServiceError>();    
    }
    
    public P2EwService.SF001Response sf003(P2EwService.SF003Request req){
        String ChangeBy; //ChangeBy = SFDC/PEGA
        String SFDCCaseID;
        String PEGACaseID;
        String PEGACaseStatus;
        
        String GroupNumber;
        String ChangeType;
        
        System.debug('req**' + req);                 
        try{
            if(req != NULL){
                System.debug('first req method**' + req);
                ChangeBy = req.ChangeBy;
                SFDCCaseID = req.SFDCCaseID;
                PEGACaseID = req.PEGACaseID;
                PEGACaseStatus = req.PEGACaseStatus;
                if(req.GroupInfo!=null){
                    for(P2EwService.QQGroup grpInfo:req.GroupInfo){
                        GroupNumber = grpInfo.GroupNumber;
                    }
                }
                ChangeType = req.ChangeType;
                
                if(ChangeBy == null || ChangeBy == ''){
                    errorList.add(new P2EwService.ServiceError('SF003-02','Required Field Missing - ChangeBy'));
                    system.debug('changeby==null'+errorList);
                    return new P2EwService.SF001Response('Error', errorList);
                }
                            
                //Change Initiated  by SFDC through IAC            
                if(SFDCCaseID != null && SFDCCaseID != '' && PEGACaseID != null && PEGACaseID != '') {
                    if(ChangeBy =='SFDC'){
                        try{
                            cse = [Select Id, AccountId, Related_Opportunity__c,Status,Group__c,Change_Type__c From Case Where Id =: SFDCCaseID Limit 1];                    
                        }catch(Exception e){
                            System.debug(e.getMessage());
                            errorList.add(new P2EwService.ServiceError('SF003-00','SFDC CaseId Missing.'));
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                    }else if(ChangeBy =='PEGA'){
                        try{
                            cse = [Select Id, AccountId, Related_Opportunity__c,Status,Group__c,Change_Type__c From Case Where Id =: SFDCCaseID and UW_Case_ID__c =: PEGACaseID Limit 1];                    
                        }catch(Exception e){
                            System.debug(e.getMessage());
                            errorList.add(new P2EwService.ServiceError('SF003-01','SFDC CaseId Missing.'));
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                    }else{
                        cse = null;
                        errorList.add(new P2EwService.ServiceError('SF003-02','Required Field Missing - ChangeBy'));
                        return new P2EwService.SF001Response('Error', errorList);
                    }
                    
                    if(cse!= NULL){
                        cse.UW_Case_ID__c = PEGACaseID;
                        cse.Status = PEGACaseStatus;
                        try{
                            //To insert error log scenario -PC-9010
                            //Line which will cause exception       - TO CHECK ERROR HANDLING                                                                                        
                            /*String abc;
                            if(abc.equals('abc')){
                                system.debug(abc);
                            }*/                                                                            
                            update cse;
                            /** T&T Start by Geetha START**/
                           /* Map<String,Date> ContractDateMap = new Map<String,Date>();//commented for 3.1
                            Set<String> cntrtIdSet = new set<String>();                           
                            for(P2EwService.QQGroup grpInfo:req.GroupInfo){
                                    Date cntrtTermDate1;
                                    if(grpInfo.GroupTermDate!=''){
                                        cntrtTermDate1 = date.valueOf(grpInfo.GroupTermDate.subString(0,4)+'-'+grpInfo.GroupTermDate.subString(4,6)+'-'+grpInfo.GroupTermDate.subString(6,8)+' 00:00:00');
                                    }
                                if(grpInfo.IsGroupTerminate==true && cntrtTermDate1!=null){
                                    cntrtIdSet.add(grpInfo.ContractId);
                                    ContractDateMap.put(grpInfo.ContractId,cntrtTermDate1);
                                }
                            }
                            if(cntrtIdSet!=null){
                                set<Id> allRenOppIdSet = new set<Id>();
                                set<Id> renOppIdSet = new set<Id>();
                                set<Id> reqOppIdSet = new set<Id>();
                                List<Contract> cntrtLst = [Select id, Group_Term_Date__c,status,Renewal_Opportunity__c,AccountId from Contract where id in:cntrtIdSet];                                                               
                                if(cntrtLst!=null){
                                    for(Contract cntrt:cntrtLst){
                                        cntrt.Group_Term_Date__c = ContractDateMap.get(cntrt.Id);
                                        if(cntrt.Group_Term_Date__c<=System.today()){
                                            cntrt.status='Terminated';
                                            cntrt.Renewal_Opportunity__c = null;
                                        }*/
                                        /*
                                        if(cntrt.Renewal_Opportunity__c!=null){
                                            allRenOppIdSet.add(cntrt.Renewal_Opportunity__c);
                                        } *///commented for 3.1
                                   /* }//commented for 3.1
                                    update cntrtLst;
                                }*/ //commented for 3.1
                                /* // Handling the same in P2EhContract
                                List<Contract> allcntrtLst = [Select id, Group_Term_Date__c,status,Renewal_Opportunity__c,AccountId from Contract where Renewal_Opportunity__c in:allRenOppIdSet and status='Activated'];
                                if(allcntrtLst!=null){
                                    for(Contract cntrt:allcntrtLst){
                                        renOppIdSet.add(cntrt.Renewal_Opportunity__c);
                                    }
                                    for(Id allRenId:allRenOppIdSet){
                                        if(!renOppIdSet.contains(allRenId)){
                                            reqOppIdSet.add(allRenId);
                                        }
                                    }
                                }
                                if(reqOppIdSet!=null){                                    
                                    set<Id> acctIdSet = new set<Id>();
                                    set<Id> allaccIdSet = new set<Id>();
                                    List<Account> acctToUpdate = new List<Account>();
                                    List<Opportunity> oppUdateLst = [select id,AccountId,stagename,Workflow_Stage__c from opportunity where id in:reqOppIdSet];
                                    for(Opportunity upOpp:oppUdateLst){
                                        upOpp.stagename='Won';
                                        upOpp.Workflow_Stage__c='Closed (After MTV Implementations)';
                                        allaccIdSet.add(upOpp.AccountId);        
                                    }
                                    update oppUdateLst;
                                    List<Contract> allcntrtLst1 = [Select id, Group_Term_Date__c,status,Renewal_Opportunity__c,AccountId from Contract where AccountId in:allaccIdSet and status='Activated'];
                                    for(Contract cnt:allcntrtLst1){                                        
                                        acctIdSet.add(cnt.AccountId);
                                    }
                                    RecordType recordtype=[select Id from RecordType where Name = 'Prospect' and SobjectType = 'Account'];
                                    List<Account> allacctLst = [select id,RecordTypeId from Account where id in:allaccIdSet];
                                    List<Account> acctLst = [select id,RecordTypeId from Account where id in:acctIdSet];
                                    for(Account acct:allacctLst){
                                        if(!acctLst.contains(acct)){
                                            acct.RecordTypeId = recordtype.Id;
                                            acctToUpdate.add(acct);  
                                        }
                                    }
                                    if(acctToUpdate!=null){
                                        update acctToUpdate;
                                    }
                                }
                               */             
                           //}
                           
                           
                           /** T&T End by Geetha END**/ 
                        }catch(Exception e){ //changed exception to P2EException 
                            System.debug(e);
                            System.debug('Line 79**');
                            
                            /*
                            errorList.add(new P2EwService.ServiceError('SF003-03','Service Failed. Contact Administrator'));
                            return new P2EwService.SF001Response('Error', errorList);
                            */
                            
                            P2EhGlobalUtil.ServiceErrorCde = 'SF003-03';
                            P2EhGlobalUtil.ServiceErrorMsg = 'Service Failed. Contact Administrator.';
                            throw new P2EException('P2EhChangeService - sf003','', e);
                        }
                    }
                     else{
                        errorList.add(new P2EwService.ServiceError('SF003-04','Required Field Missing - ChangeBy'));
                        return new P2EwService.SF001Response('Error', errorList);
                    }
                    return (new P2EwService.SF001Response('OK'));
                }
                
                //Change Initiated  by PEGA            
                if((SFDCCaseID == null || SFDCCaseID == '') && ChangeBy =='PEGA') {
                    if(GroupNumber!=null){
                        try{
                            contr = [Select AccountId, Opportunity__c, Renewal_Opportunity__c from contract where Group_Number__c =:GroupNumber Limit 1];
                        }catch(QueryException e){
                            System.debug('Query Exception ::: ' + e.getMessage());
                            errorList.add(new P2EwService.ServiceError('SF003-05','Service Failed. Contact Administrator'));
                            return new P2EwService.SF001Response('Error', errorList);
                        }catch(Exception e){
                            System.debug('Exception ::: ' + e.getMessage());
                            errorList.add(new P2EwService.ServiceError('SF003-06','Service Failed. Contact Administrator'));
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                    }
                    caseInsertion=new Case();
                    caseInsertion.AccountId=contr.AccountId;
                    caseInsertion.Related_Opportunity__c = contr.Renewal_Opportunity__c;
                    caseInsertion.Status='New';
                    caseInsertion.Type='Change';
                    caseInsertion.Origin='Web';
                    caseInsertion.Group__c  = GroupNumber;
                    caseInsertion.Change_Type__c =ChangeType;
                    if(PEGACaseID != NULL){
                        caseInsertion.UW_Case_ID__c = PEGACaseID;
                    }else{
                        errorList.add(new P2EwService.ServiceError('SF003-07','Required Field Missing - PEGACaseID'));
                        return new P2EwService.SF001Response('Error', errorList);
                    }                      
                    try{
                        insert caseInsertion;
                    }catch(Exception e){
                        System.debug('caseInsertion Failed ::: ' + caseInsertion);
                        errorList.add(new P2EwService.ServiceError('SF003-08','Service Failed. Contact Administrator'));
                        return new P2EwService.SF001Response('Error', errorList);
                    }
                    P2EwService.SF003Response sf003Resp = new P2EwService.SF003Response();
                    sf003Resp.SFDCCaseID = caseInsertion.Id;
                    P2EwService.SF001Response resp = new P2EwService.SF001Response('OK');
                    resp.SF003 = sf003Resp;
                    return resp;
                }                
            }
              errorList.add(new P2EwService.ServiceError('SF003-09','Service Failed. To Provide the Request'));
              return new P2EwService.SF001Response('Error', errorList);        
              //  return null;
          }catch(Exception e){
            P2EhGlobalUtil.ServiceErrorCde = 'SF003-000';
            P2EhGlobalUtil.ServiceErrorMsg = 'Service Failed. Contact Administrator.';
            throw new P2EException('P2EhChangeService- sf003','', e);
          }
    }
    
}