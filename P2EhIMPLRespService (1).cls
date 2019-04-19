public class P2EhIMPLRespService {
    public List<P2EwService.ServiceError> errorList;
    public P2EwService.SF001Response resp;
    Public String reqCaseId;
    //Public static Boolean isSf002;
    public P2EhIMPLRespService(){
        errorList = new List<P2EwService.ServiceError>();
        //isSf002=false;
    }
    
    public P2EwService.SF001Response sf002(P2EwService.SF002Request req){
        try{    
            if(req != null){
                system.debug('request'+req);
                //req = null; //To insert error log scenario -PC-9010
                if(req.Contract!=null){
                    Map<String, P2EwService.QQContract> reqGrpTermMap = new Map<String, P2EwService.QQContract>();
                    Map<String, P2EwService.QQContract> reqGrpMap = new Map<String, P2EwService.QQContract>();
                    Map<String, P2EwService.QQContract> reqGrpClnMap = new Map<String, P2EwService.QQContract>();
                    Map<String, Integer> reqMulGrpCln = new Map<String, Integer>();
                    Map<String, Set<String>> reqGrpPlansMap = new Map<String, Set<String>>();
                    Map<Date, Set<String>> reqDateGrpsMap = new Map<Date, Set<String>>();
                    Map<String,List<P2EwService.QQBenefits>> grpBenefitsMap = new Map<String,List<P2EwService.QQBenefits>>();//by Geetha for 14083
                    Map<String,Set<String>> grpBenpackIdMap = new Map<String,Set<String>>();//by Geetha for 14083//3.1
                    Map<String, Set<Id>> reqGrpCntIdMap = new Map<String, Set<Id>>();
                    Map<String, Set<String>> reqGrpNewCntMap = new Map<String, Set<String>>();
                    Map<String, P2EwPegaService.QQContacts> reqNewContMap = new Map<String, P2EwPegaService.QQContacts>();
                    Map<String, String> reqPlanIdGroupPlanMap = new Map<String, String>();    // Added by Murali for PC-15498
                    Map<String, Set<String>> reqPlanIdBPIdMap = new Map<String, Set<String>>();   // Added by Murali for PC-15498                    
                    Set<String> planIds;
                    Set<String> grpNbrs;
                    List<Contract> contractsToUpsert = new List<Contract>();                    
                    List<Group_Info_History__c> gihListToUpdate=new List<Group_Info_History__c>();//3.1
                    Map<String,Group_Info_History__c> mapGrpGIHUpdated = new Map<String,Group_Info_History__c>();//3.1
                    List<Opportunity> lstOppToBeUpdated = new List<Opportunity>();
                    String reqCaseStatus;
                    Boolean isClosure;
                    Map<Id, List<Id>> mapProdIdNewRSId = new Map<Id, List<Id>>(); //Added by Parthiban 21-09-2016
                    Integer newContactCnt = 0;
                    Set<String> allBPIdSet = new Set<String>();//Geetha PC-15498                    
                    for(P2EwService.QQContract reqCont : req.Contract){
                        if(reqCont.CaseID!=null){
                            if(reqCont.GroupNumber!=null){
                                if(reqCont.ClonedGroupNumber == null || reqCont.ClonedGroupNumber == ''){
                                    if(reqGrpMap.get(reqCont.GroupNumber)!=null){
                                        errorList.add(new P2EwService.ServiceError('SF002-10','Identified duplicate GroupNumber ('+ reqCont.GroupNumber +') in request.'));
                                        break;
                                    }
                                    /*else if(reqCont.isTerminated != NULL && reqCont.isTerminated == True){//reqCont.isTerminated//commnented for 3.1
                                        reqGrpTermMap.put(reqCont.GroupNumber, reqCont);
                                    }*/ //commented for 3.1
                                    else{
                                        reqGrpMap.put(reqCont.GroupNumber, reqCont);
                                        if(reqCont.Benefits!=null){
                                            for(P2EwService.QQBenefits reqBen : reqCont.Benefits){
                                                if(reqBen.PlanId!=null && reqBen.PlanId!=''){
                                                    if(reqGrpPlansMap.get(reqCont.GroupNumber)!=null){
                                                        planIds = reqGrpPlansMap.get(reqCont.GroupNumber);
                                                    }else{
                                                        planIds = new Set<String>();
                                                    }
                                                    planIds.add(reqBen.PlanId);
                                                    reqGrpPlansMap.put(reqCont.GroupNumber, planIds);
                                                }else{
                                                    errorList.add(new P2EwService.ServiceError('SF002-09','PlanId missing.'));
                                                    break;
                                                }
                                            }
                                        }
                                    }   
                                    
                                    if(reqCont.Benefits!=null){//14083
                                       for(P2EwService.QQBenefits reqBen : reqCont.Benefits){
                                           if(grpBenefitsMap.get(reqCont.GroupNumber)==null){
                                                grpBenefitsMap.put(reqCont.GroupNumber,new List<P2EwService.QQBenefits>());
                                           }
                                           grpBenefitsMap.get(reqCont.GroupNumber).add(reqBen);
                                           
                                           
                                           /*** Added by Murali for Missing BP Solution(PC-15498) - Start ***/
                                           if(reqBen.PlanId !=null && reqBen.PlanId!=''){
                                                reqPlanIdGroupPlanMap.put(reqBen.PlanId,reqBen.GroupPlanName);
                                           }
                                           Set<String> BPIdSet = new Set<String>();
                                           system.debug('BenefitPackages :::' + reqBen.BenefitPackages);
                                           system.debug('GroupCaseID:::' + reqBen.GroupCaseID.contains('BC-'));
                                           system.debug('GroupCaseID:::' + reqBen.GroupCaseID.contains('NG-'));
                                           system.debug('reqBen.GroupCaseID' + reqBen.GroupCaseID);
                                           if(reqBen.BenefitPackages!=null && reqBen.BenefitPackages.size()>0 && !reqBen.BenefitPackages.isEmpty()){
                                                for(P2EwService.QQBenefitPackages reqBP:reqBen.BenefitPackages){
                                                    BPIdSet.add(reqBP.BPID.toUpperCase());
                                                    //3.1 Start
                                                    if(grpBenpackIdMap.get(reqCont.GroupNumber)==null){
                                                         grpBenpackIdMap.put(reqCont.GroupNumber,new set<String>());
                                                    }
                                                    grpBenpackIdMap.get(reqCont.GroupNumber).add(reqBP.BPID.toUpperCase());
                                                    //3.1 End
                                                }
                                                reqPlanIdBPIdMap.put(reqBen.PlanId,BPIdSet);
                                                for(String bpid1:BPIdSet){
                                                    allBPIdSet.add(bpid1.toUpperCase());// Geetha PC-15498
                                                }
                                           }else if((reqBen.BenefitPackages==null || reqBen.BenefitPackages.size()==0 || reqBen.BenefitPackages.isEmpty()) && (reqBen.GroupCaseID.contains('NG-') || reqBen.GroupCaseID.contains('BC-')) && req.SkipBPIDValidation==false){
                                                system.debug('HIIIIIII if');
                                                if(reqBen.PlanId !=null && reqBen.PlanId!=''){
                                                    errorList.add(new P2EwService.ServiceError('SF002-20','BenefitPackages missing for the planId: '+reqBen.PlanId+' in the group case '+reqBen.GroupCaseID));
                                                }                                                    
                                           }
                                           
                                           
                                           
                                         
                                           /*** PC-15498 End ***/
                                       }
                                       system.debug('alBPIDSet'+allBPIdSet);
                                    }// Till here for 14083
                                    
                                    //Fix for HEAT 1725499 - Start
                                    /*if(reqCont.ContractTermFrom == Null && reqCont.CaseStatus == 'Resolved-Completed'){//commented for 3.1 
                                        errorList.add(new P2EwService.ServiceError('SF002-08','ContractTermFrom is Mandatory'));
                                        break;                                        
                                    }*/ //commented for 3.1                                    
                                    /*if(reqCont.ContractTermTo == Null && reqCont.CaseStatus == 'Resolved-Completed'){//commented for 3.1 
                                        errorList.add(new P2EwService.ServiceError('SF002-08','ContractTermTo is Mandatory'));
                                        break;                                            
                                    }*/ //commented for 3.1
                                    //Fix for HEAT 1725499 - End. Modified by Parthiban P 24/02/2016                                    
                                    /*if(reqCont.ContractTermTo!=null && reqCont.ContractTermTo!=''){//commented for 3.1
                                        if(reqDateGrpsMap.get(reqCont.ContractTermTo)!=null){
                                            grpNbrs = reqDateGrpsMap.get(reqCont.ContractTermTo);
                                        }else{
                                            grpNbrs = new Set<String>();
                                        }
                                        grpNbrs.add(reqCont.GroupNumber);
                                        reqDateGrpsMap.put(reqCont.ContractTermTo, grpNbrs);
                                    }*/ //commented for 3.1
                                    Set<Id> contIds;
                                    if(reqCont.Contacts!=null && reqCont.Contacts.size()>0){
                                        for(P2EwPegaService.QQContacts cont : reqCont.Contacts){                                        
                                            if(cont.ContactID!=null && cont.ContactID!=''){
                                                if(cont.AddressesList!=null){
                                                    for(P2EwPegaService.QQAddressesList al : cont.AddressesList){
                                                        if(al.State == null){
                                                            errorList.add(new P2EwService.ServiceError('SF002-90','State for a Contact is Mandatory'));
                                                            break;
                                                        }
                                                    }
                                                }
                                                if(reqGrpCntIdMap.get(reqCont.GroupNumber)!=null){
                                                    contIds = reqGrpCntIdMap.get(reqCont.GroupNumber);
                                                }else{
                                                    contIds = new Set<Id>();
                                                }
                                                contIds.add(Id.valueOf(cont.ContactID));
                                                reqGrpCntIdMap.put(reqCont.GroupNumber, contIds);
                                            }else{
                                                newContactCnt++;
                                                cont.ContactID = String.valueOf(newContactCnt);
                                                Set<String> newConts;
                                                if(reqGrpNewCntMap.get(reqCont.GroupNumber)!=null){
                                                    newConts = reqGrpNewCntMap.get(reqCont.GroupNumber);
                                                }else{
                                                    newConts = new Set<String>();
                                                }
                                                newConts.add(cont.ContactID);
                                                reqGrpNewCntMap.put(reqCont.GroupNumber, newConts);
                                                reqNewContMap.put(cont.ContactID, cont);
                                            }
                                        }
                                    }
                                }else{
                                    if(reqGrpClnMap.get(reqCont.GroupNumber)!=null){
                                        errorList.add(new P2EwService.ServiceError('SF002-07','GroupNumber missing from one of the contract.'));
                                        break;
                                    }else{
                                        reqGrpClnMap.put(reqCont.GroupNumber, reqCont);
                                        Integer count;
                                        if(reqMulGrpCln.get(reqCont.ClonedGroupNumber)!=null){
                                            count = reqMulGrpCln.get(reqCont.ClonedGroupNumber);
                                        }else{
                                            count = 0;
                                        }
                                        reqMulGrpCln.put(reqCont.ClonedGroupNumber, count+1);
                                    }
                                }
                            }else if(reqCont.Benefits!=null && (reqCont.GroupNumber == null || reqCont.GroupNumber=='')){//geetha
                                errorList.add(new P2EwService.ServiceError('SF002-06','GroupNumber missing in One of the Contract.'));
                                break;
                            }
                            if(reqCaseId==null || reqCaseId==reqCont.CaseID){
                                reqCaseId = reqCont.CaseID;
                            }else{
                                errorList.add(new P2EwService.ServiceError('SF002-05','Multiple Parent CaseID found in request.'));
                                break;
                            }                            
                            if(reqCaseStatus==null || reqCaseStatus==reqCont.CaseStatus){
                                reqCaseStatus = reqCont.CaseStatus;
                            }else{
                                errorList.add(new P2EwService.ServiceError('SF002-04','Different Parent CaseStatus found in request.'));
                                break;
                            }                            
                        }else{
                            errorList.add(new P2EwService.ServiceError('SF002-02','CaseID missing in One of the Contract.'));
                            break;
                        }
                    }
                    
                    //3.1 Start
                    Map<String,Contract> mapGroupContract=new Map<String,Contract>();
                    //Map<String,Contract> mapGroupMasterContract=new Map<String,Contract>();
                    Map<String,List<Group_Info_History__c>> mapGrpGroupInfoHistoryList = new Map<String,List<Group_Info_History__c>>();
                    Map<String,List<Group_Info_History__c>> mapGrpGroupInfoHistoryLatestList = new Map<String,List<Group_Info_History__c>>();
                    
                    set<String> grpId=new set<String>();
                    grpId=reqGrpMap.keyset();
                    
                    List<Contract> existingGroups=Database.Query(P2EhUtility.getQuery('Contract') + ' WHERE Group_Number__c in:grpId AND (Status =\'Draft\' OR Status =\'Activated\' OR Status=\'Terminated\') ORDER BY Status DESC NULLS LAST');
                  
                    List<Group_Info_History__c> groupInfoHistoryList=Database.Query(P2EhUtility.getQuery('Group_Info_History__c') + ' WHERE Group_Number__c in:grpId AND Group_Info_Master__c !=null AND (update_type__c =\'Renewal\' OR update_type__c =\'Change\' OR update_type__c=\'Extension\') AND Status__c=\'Activated\'');
                    system.debug('groupInfoHistoryList'+groupInfoHistoryList);
                    if(groupInfoHistoryList.size()>0){
                        for(Group_Info_History__c gih:groupInfoHistoryList){
                            if(!mapGrpGroupInfoHistoryList.containsKey(gih.Group_Number__c)){
                                mapGrpGroupInfoHistoryList.put(gih.Group_Number__c,new List<Group_Info_History__c>());
                            }
                            mapGrpGroupInfoHistoryList.get(gih.Group_Number__c).add(gih);
                        }
                    }
                    system.debug('mapGrpGroupInfoHistoryList'+mapGrpGroupInfoHistoryList);                                            
                    for(Contract existingcntrt:existingGroups){
                        if(existingcntrt.Status!=null){
                            if(existingcntrt.Status=='Draft' && existingcntrt.IsMaster__c==false){
                                if((!mapGroupContract.isEmpty() && !mapGroupContract.containsKey(existingcntrt.Group_Number__c)) || (mapGroupContract.isEmpty())){
                                    mapGroupContract.put(existingcntrt.Group_Number__c,existingcntrt);
                                }
                            }                            
                            else if((existingcntrt.Status=='Activated' || existingcntrt.Status=='Terminated') && existingcntrt.IsMaster__c==true){
                                system.debug('into else');
                                if((!mapGroupContract.isEmpty() && !mapGroupContract.containsKey(existingcntrt.Group_Number__c)) || (mapGroupContract.isEmpty())){
                                    mapGroupContract.put(existingcntrt.Group_Number__c,existingcntrt);
                                    system.debug('mapGroupContract'+mapGroupContract);
                                    if(existingcntrt.Status=='Activated'){                                
                                        if(!mapGrpGroupInfoHistoryList.isEmpty() && mapGrpGroupInfoHistoryList.containsKey(existingcntrt.Group_Number__c) && mapGrpGroupInfoHistoryList.get(existingcntrt.Group_Number__c).size()>0){
                                            DateTime Largest=mapGrpGroupInfoHistoryList.get(existingcntrt.Group_Number__c)[0].Contract_End_Date__c;                                 
                                            for(Group_Info_History__c gih:mapGrpGroupInfoHistoryList.get(existingcntrt.Group_Number__c)){
                                                if(gih.Contract_End_Date__c>Largest){
                                                    Largest=gih.Contract_End_Date__c;
                                                }
                                            }
                                            system.debug('Largest'+Largest);
                                            for(Group_Info_History__c gih:mapGrpGroupInfoHistoryList.get(existingcntrt.Group_Number__c)){
                                                if(Largest==gih.Contract_End_Date__c){
                                                    system.debug('into Largest if');
                                                    if(!mapGrpGroupInfoHistoryLatestList.containsKey(gih.Group_Number__c)){
                                                        mapGrpGroupInfoHistoryLatestList.put(gih.Group_Number__c,new List<Group_Info_History__c>());
                                                    }
                                                    mapGrpGroupInfoHistoryLatestList.get(gih.Group_Number__c).add(gih);
                                                }
                                            }
                                        }
                                    }
                                }                                                                           
                            }
                        }
                    }                    
                    for(String grpNo:reqGrpMap.keyset()){
                        if(!mapGroupContract.isEmpty() && mapGroupContract.containsKey(grpNo) && mapGroupContract.get(grpNo).Status=='Draft'){
                            errorList.add(new P2EwService.ServiceError('SF002-333','Transient Group Found for the Group, '+grpNo+'. Please complete the steps in Group Configurator.'));                            
                        }
                        if((!mapGroupContract.isEmpty() && !mapGroupContract.containsKey(grpNo)) || mapGroupContract.isEmpty()){
                            errorList.add(new P2EwService.ServiceError('SF002-333','No Group Found for, '+grpNo+'. Please complete the steps in Group Configurator.'));                            
                        }
                    }
                
                    for(Contract cntrt:mapGroupContract.values()){ 
                        if(cntrt.Status=='Activated'){                                                   
                            if(cntrt.EndDate!=null){
                                if(reqDateGrpsMap.get(cntrt.EndDate)!=null){
                                    grpNbrs = reqDateGrpsMap.get(cntrt.EndDate);
                                }else{
                                    grpNbrs = new Set<String>();
                                }
                                grpNbrs.add(cntrt.Group_Number__c);
                                reqDateGrpsMap.put(cntrt.EndDate, grpNbrs);
                            }
                        }
                    }
                    
                    /*if(mapGroupContract.size()>0){
                        for(Contract existingcntrt:existingGroups){
                            for(Contract cntrt: mapGroupContract.values()){
                                if(cntrt.Status=='Draft' && cntrt.Group_Info_Master__c==existingcntrt.Id && existingcntrt.Status=='Activated'){
                                    if(!mapGroupMasterContract.containsKey(existingcntrt.Group_Number__c)){
                                        mapGroupMasterContract.put(existingcntrt.Group_Number__c,existingcntrt);
                                    }
                                }
                            }
                        }
                    }*/
                                    
                                           
                    //3.1 End            
                        
                    
                     /*if(req.TermAndTransfer!=null){ // commented for 3.1
                        //isSf002=true;
                        P2EwService.TermAndTransferNode ttnode=req.TermAndTransfer;
                        if(ttnode.GroupInfo!=null){*/ //commented for 3.1
                            /** T&T Start **/
                            /*Map<String,Date> ContractDateMap = new Map<String,Date>(); //commented for 3.1
                            Set<String> cntrtIdSet = new set<String>();
                            for(P2EwService.QQGroup grpInfo:ttnode.GroupInfo){
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
                                        }
                                        contractsToUpsert.add(cntrt);                                        
                                    }
                                    //update cntrtLst;
                                }                                    
                           }
                           
                        }
                    }*/ //commented for 3.1
                    /** T&T End **/ 
                    system.debug('reqGrpNewCntMap :: ' + reqGrpNewCntMap);
                    system.debug('reqNewContMap :: '+ reqNewContMap);
                    
                    if(errorList.size()>0){
                      return new P2EwService.SF001Response('Error', errorList);
                    }
                    
                    if(errorList.isEmpty()){                      
                      if(reqCaseId==null){
                        errorList.add(new P2EwService.ServiceError('SF002-99','No CaseId in request'));
                      }
                      if(reqCaseStatus==null){
                        errorList.add(new P2EwService.ServiceError('SF002-99','No CaseStatus in request'));
                      }
                      if(errorList.size()>0){
                        return new P2EwService.SF001Response('Error', errorList);
                      }
                    }
                    
                    System.Savepoint sp = Database.setSavepoint();
                    
                    if(reqCaseId!=null){
                        Case caseToUpdate;
                        Id oppId;
                        String oppName;
                        String oppType;
                        Id accId;
                        Date oppEndDate;
                        Boolean isOpptyToCreate = true;//13770
                        try{
                            caseToUpdate = [Select Id, Group__c, Related_Opportunity__c, Related_Opportunity__r.Name, Related_Opportunity__r.CloseDate, Related_Opportunity__r.Type, Related_Opportunity__r.AccountId, Status, Parent_Impl_Case_Id__c, Parent_Impl_Case_Status__c, Subject From Case Where Parent_Impl_Case_Id__c =: reqCaseId Limit 1];
                            
                            oppId = caseToUpdate.Related_Opportunity__c;
                            oppName = caseToUpdate.Related_Opportunity__r.Name;
                            accId = caseToUpdate.Related_Opportunity__r.AccountId;
                            oppType = caseToUpdate.Related_Opportunity__r.Type;
                            oppEndDate = caseToUpdate.Related_Opportunity__r.CloseDate.addDays(-1); 
                        }catch(QueryException e){
                            errorList.add(new P2EwService.ServiceError('SF002-22','IM Case requested - ' + reqCaseId + ' does not exist.'));
                            system.debug('caseToUpdate query failed :::' + caseToUpdate);
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-22','Service Failed. Contact Administrator.'));
                            system.debug('caseToUpdate query failed :::' + caseToUpdate);
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        
                        if(caseToUpdate.Status == 'Resolved-Completed'){
                            errorList.add(new P2EwService.ServiceError('SF002-001', reqCaseId + ' has been already closed (Resolved-Completed).'));
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        
                        /********************************************************************************/
                        //Fetch OLI
                        List<OpportunityLineItem> OLIList = [select product2.PlanID__c, PlanID__c, Quantity, Contract_Reference__c,TotalPrice,Action__c,  
                                                        Product2Id,QQ_Case_Id__c,RFP_Case_Id__c,Group_Number__c, Group_Name__c, Id,Impl_Case_Id__c,Impl_Case_Status__c,Parent_Impl_Case_Id__c,
                                                        Parent_Impl_Case_Status__c, pricebookentryId, product2.Name, OpportunityId, Opportunity.Type, Opportunity.Case__c, 
                                                        Opportunity.AccountId, Opportunity.Name,Par_Impl_case_Id_Hide__c,Par_Impl_case_status_Hide__c,PDLJSON__c from OpportunityLineItem where //Decision_Status__c IN ('Sold', 'Not - Sold')  
                                                        //and 
                                                        Parent_Impl_Case_Id__c =: reqCaseId];
                        
                        /********************************************************************************/
                        //Update the fetched OLIs with values coming in Request
                        Set<String> rfpids = new set<String>();
                        Map<String, Set<Id>> reqGrpProdIdMap = new Map<String, Set<Id>>();
                        for(OpportunityLineItem oli : OLIList){
                            for(String grpNbr : reqGrpMap.keyset()){
                                P2EwService.QQContract reqCont = reqGrpMap.get(grpNbr);//13770
                                if(reqGrpPlansMap.get(grpNbr).contains(oli.product2.PlanID__c) 
                                        && oli.Parent_Impl_Case_Id__c == reqCaseId
                                        && oli.OpportunityId == oppId){
                                        if(reqGrpMap.get(grpNbr).Benefits!=null){//geetha
                                            for(P2EwService.QQBenefits ben : reqGrpMap.get(grpNbr).Benefits){
                                                if(ben.PlanId == oli.product2.PlanID__c){
                                                    oli.Impl_Case_Id__c = ben.GroupCaseID;
                                                    oli.Impl_Case_Status__c = ben.GroupCaseStatus;
                                                }
                                            }
                                        }
                                    system.debug('reqGrpMap.get(grpNbr) :: ' + reqGrpMap.get(grpNbr));    
                                    system.debug('reqGrpPlansMap.get(grpNbr) :: ' + reqGrpPlansMap.get(grpNbr));
                                    system.debug('oli.product2.PlanID__c :: ' + oli.product2.PlanID__c);
                                    system.debug('oli.OpportunityId :: ' + oli.OpportunityId);
                                    system.debug('grpNbr :: ' + grpNbr);
                                    
                                    //oli update
                                    //oli.Group_Name__c = reqGrpMap.get(grpNbr).GroupName;
                                    if(reqGrpMap.get(grpNbr).GroupNumber!=null){//geetha
                                        oli.Group_Number__c = reqGrpMap.get(grpNbr).GroupNumber;
                                        oli.Parent_Impl_Case_Status__c = reqGrpMap.get(grpNbr).CaseStatus; //reqCaseStatus
                                        if(oli.Parent_Impl_Case_Id__c!=null && oli.Par_Impl_case_Id_Hide__c!=null && oli.Par_Impl_case_status_Hide__c=='Pending-Review'){
                                            oli.Par_Impl_case_status_Hide__c = reqGrpMap.get(grpNbr).CaseStatus;
                                        }
                                    }
                                    //oli.Contract_Reference__c = grpContractMap.get(grpNbr).ContractNumber;
                                    
                                    //Frame reqGrpProdIdMap
                                    Set<Id> prodIds;
                                    /*Date cntrtTermDate1;//13770//commented for 3.1
                                    if(reqCont.GroupTermDate!=''){
                                        cntrtTermDate1 = date.valueOf(reqCont.GroupTermDate.subString(0,4)+'-'+reqCont.GroupTermDate.subString(4,6)+'-'+reqCont.GroupTermDate.subString(6,8)+' 00:00:00');
                                    }*/ //till here for 13770 //commented for 3.1
                                    if(reqGrpProdIdMap.get(grpNbr)!=null){
                                        prodIds = reqGrpProdIdMap.get(grpNbr);
                                    }else{
                                        prodIds = new Set<Id>();
                                    }
                                    //prodIds.add(oli.Product2Id);
                                    
                                     if((!grpBenefitsMap.isEmpty() || grpBenefitsMap!=null) && grpBenefitsMap.get(grpNbr)!=null){//14083
                                            for(P2EwService.QQBenefits reqBen : grpBenefitsMap.get(grpNbr)){
                                                if(reqBen.PlanId == oli.product2.PlanID__c){//updated for 3.1
                                                    prodIds.add(oli.Product2Id);
                                                }
                                            }
                                    }//till here for 14083
                                    
                                    reqGrpProdIdMap.put(grpNbr, prodIds);    
                                }
                            }
                            system.debug('reqGrpMap'+reqGrpMap);
                            system.debug('reqGrpPlansMap'+reqGrpPlansMap);
                            if(reqGrpMap.isEmpty() && reqGrpPlansMap.isEmpty()){//geetha
                                 system.debug('hiiii if');
                                 oli.Parent_Impl_Case_Status__c = reqCaseStatus;
                                 rfpids.add(oli.RFP_Case_Id__c); 
                            }//geetha
                        }
                        if(reqCaseStatus!=null && reqCaseStatus.contains('Resolved') && reqCaseStatus!='Resolved-Completed'){                                                             
                                List<Quote> qtlist = [select id,Status from quote where OpportunityId =: oppId and Status!='Withdrawn' and RFP_Case_Id__c in:rfpids];
                                set<Id> qids = new set<Id>();
                                for(Quote qt:qtlist){
                                   qids.add(qt.Id); 
                                }
                                //Quote qt = [select id,Status from quote where OpportunityId =: oppId limit 1];
                                P2EhUtility.withdrawfunc(qids);
                        }
                        if(reqCaseStatus!=null){
                            caseToUpdate.Group__c = '';
                            for(String grpNbr : reqGrpMap.keyset()){
                                caseToUpdate.Group__c += grpNbr + ',';
                            }
                            caseToUpdate.Group__c = caseToUpdate.Group__c.removeEnd(',');
                            caseToUpdate.Parent_Impl_Case_Id__c = reqCaseId;
                            caseToUpdate.UW_Case_ID__c = reqCaseId;
                            caseToUpdate.Status = reqCaseStatus;
                            try{
                                update caseToUpdate;
                            }catch(Exception e){
                                errorList.add(new P2EwService.ServiceError('SF002-111','Service Call Failed. Contact Administrator.'));
                                system.debug('caseToUpdate update Failed :::' + caseToUpdate);
                                system.debug(e.getMessage());
                                Database.rollback(sp);
                                return new P2EwService.SF001Response('Error', errorList);
                            }
                        }
                        
                        try{
                            //system.debug('contOLIMap  :: ' + contOLIMap);
                            system.debug('OLIList normal update (should also work for Cloned Group) :: ' + OLIList);
                            update OLIList;
                            system.debug('OLIList after insert :: ' + OLIList);
                            
                            //Added as part of PC-12785                            
                            boolean allCompleted = true;    
                            Opportunity oppToUpdate = [Select id,name,type,stagename,Workflow_Stage__c from opportunity where id =:oppId];                             
                            //List<Opportunity> lstOppToBeUpdated = new List<Opportunity>();                            
                            List<OpportunityLineItem> lstOppOli =[select id,name,IsRerate__c,OpportunityId,Impl_Case_Status__c,Parent_Impl_Case_Status__c,Status__c,product2.PlanID__c,PlanID__c,Product2Id,Group_Number__c,Action__c,Decision_Status__c from OpportunityLineItem where OpportunityId =:oppId AND Parent_Impl_Case_Id__c  != NULL];//modified the query for PC-15498//Added Decision_Status__c in the query for PC-16748
                            System.debug('lstOppOli size**' + lstOppOli.size());                            
                            for(OpportunityLineItem oli : lstOppOli){
                                 if((oli.Parent_Impl_Case_Status__c != 'Resolved-Completed' && (oli.Decision_Status__c=='Sold' || (oli.Decision_Status__c=='Not - Sold' && oli.Action__c=='Discontinue'))) || oli.IsRerate__c==true){//2nd condition added by Geetha for PC-13178//modified the condition for PC-16748 by Geetha
                                    allCompleted = false;
                                    break; 
                                }                                    
                            }
                            if(allCompleted){
                                    /*List<Case> ttCaseLst = [select id,status from case where Related_Opportunity__c=:oppId AND Term_Transfer_Type__c!=null AND Term_And_Transfer__c=true AND Change_Type__c=null AND Change_SubType__c=null];//commented for 3.1
                                    if(ttCaseLst!=null){
                                        for(Case cas:ttCaseLst){
                                            cas.status='Resolved-Completed';
                                        }
                                        update ttCaseLst;
                                    }*/ //commented for 3.1
                                    System.debug('All the records have parent impl cases status -Resolved Completed'); 
                                    
                                    if(oppToUpdate.type =='New'){
                                        //oppToUpdate.stagename = 'Closed (After MTV Implementations)';
                                        oppToUpdate.stagename = Label.Sales_Stages_Won;
                                        oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Closed_After_MTV_Implementations;   
                                        lstOppToBeUpdated.add(oppToUpdate); 
                                    } 
                                    else if(oppToUpdate.type =='Renewal'){
                                         //oppToUpdate.stagename = 'Closed (After MTV Implementations)';
                                         oppToUpdate.stagename = Label.Sales_Stages_Won;  
                                         oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Closed_After_MTV_Implementations;    
                                         lstOppToBeUpdated.add(oppToUpdate);
                                    }
                                    else if(oppToUpdate.type =='Change'){
                                         //oppToUpdate.stagename = 'Closed - Change Implemented';
                                         oppToUpdate.stagename = Label.Sales_Stages_Closed_Change_Implemented;
                                         oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Closed_Change_Implemented;
                                         lstOppToBeUpdated.add(oppToUpdate);                                       
                                    }     
                                                                 
                            }else{                            
                                System.debug('All the records not having parent impl cases status -Resolved Completed');                                 
                                if(oppToUpdate.type =='New'){
                                    //oppToUpdate.stagename = 'Implementation in Progress';
                                    oppToUpdate.stagename = Label.Sales_Stages_Won;
                                    oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Implementation_in_Progress;
                                    lstOppToBeUpdated.add(oppToUpdate);
                                }
                                else if(oppToUpdate.type =='Renewal'){
                                     //oppToUpdate.stagename = 'Renewal Implementation in Progress';
                                     oppToUpdate.stagename = Label.Sales_Stages_Renewal_Implementation_in_Progress;   
                                     oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Renewal_Implementation_in_Progress;   
                                     lstOppToBeUpdated.add(oppToUpdate);
                                }
                                else if(oppToUpdate.type =='Change'){
                                     //oppToUpdate.stagename = 'Change Implementation in Progress';
                                     oppToUpdate.stagename = Label.Sales_Stages_Change_Implementation_in_Progress;
                                     oppToUpdate.Workflow_Stage__c = Label.Sales_Stages_Change_Implementation_in_Progress;
                                     lstOppToBeUpdated.add(oppToUpdate);                                       
                                }                                                            
                            }
                            update lstOppToBeUpdated;                            
                            //Added as part of PC-12785
                            Map<String,List<OpportunityLineItem>> mapGrpOLI = new Map<String,List<OpportunityLineItem>>();//Geetha PC-15498
                            Set<Id> disPrdIdSet = new set<Id>();
                            for(OpportunityLineItem oli : lstOppOli){
                                for(String grpNbr : reqGrpMap.keyset()){
                                    P2EwService.QQContract reqCont = reqGrpMap.get(grpNbr);
                                    if(oli.Group_Number__c==reqCont.GroupNumber){
                                        if(mapGrpOLI.get(reqCont.GroupNumber)==null || mapGrpOLI.get(reqCont.GroupNumber).size()==0){
                                            mapGrpOLI.put(reqCont.GroupNumber,new List<OpportunityLineItem>());
                                        }
                                        mapGrpOLI.get(reqCont.GroupNumber).add(oli);
                                    }
                                }
                            }
                            Boolean isError=false;                                                                        
                            for(P2EwService.QQContract reqCont : req.Contract){
                                /*Date cntrtTermDate;//13770//commented for 3.1
                                if(reqCont.GroupTermDate!=''){
                                    cntrtTermDate = date.valueOf(reqCont.GroupTermDate.subString(0,4)+'-'+reqCont.GroupTermDate.subString(4,6)+'-'+reqCont.GroupTermDate.subString(6,8)+' 00:00:00');
                                }*/ //13770  //commented for 3.1                                                                                   
                                for(P2EwService.QQBenefits reqBen : grpBenefitsMap.get(reqCont.GroupNumber)){
                                    for(OpportunityLineItem oliDC:mapGrpOLI.get(reqCont.GroupNumber)){                                                                       
                                       if(reqBen.PlanId==oliDC.product2.PlanID__c && oliDC.Action__c=='Discontinue' && reqBen.GroupCaseID.contains('CH-')){                                           
                                           if(reqBen.BenefitPackages!=null && reqBen.BenefitPackages.size()>0 && !reqBen.BenefitPackages.isEmpty()){
                                               errorList.add(new P2EwService.ServiceError('SF002-30','BenefitPackages should be empty for the discontinued planId: '+reqBen.PlanId+' in the group case '+reqBen.GroupCaseID));
                                               isError=true;
                                           }
                                           if(reqCont.GroupTermDate=='' && reqCont.IsGroupTerminate==False){
                                               disPrdIdSet.add(oliDC.product2Id);
                                           } 
                                       }                                                                                                             
                                    }
                                }                                                        
                            }
                            if(isError){
                                Database.rollback(sp);
                                return new P2EwService.SF001Response('Error', errorList); 
                            }
                            else if(disPrdIdSet.size()>0){
                                List<ProdBenefit__c> prdBenLstToDelete = [select id,Benefit_Package__c,Benefit_Package_ID__c,Product__c,Benefit_Package__r.Id from ProdBenefit__c where Product__c in:disPrdIdSet];
                                if(prdBenLstToDelete.size()>0){
                                    delete prdBenLstToDelete;
                                }
                            }
                                
                                
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-101','Service Call Failed. Contact Administrator.'));
                            system.debug('OLIList update Failed :::' + OLIList);
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        } 
                        /*List<OpportunityLineItem> OLIListNew = [select product2.PlanID__c,Decision_Status__c, PlanID__c, Quantity, Contract_Reference__c,TotalPrice,Action__c,  
                                                    Product2Id,QQ_Case_Id__c,RFP_Case_Id__c,Group_Number__c, Group_Name__c, Id,Impl_Case_Id__c,Impl_Case_Status__c,Parent_Impl_Case_Id__c,
                                                    Parent_Impl_Case_Status__c, pricebookentryId, product2.Name, OpportunityId, Opportunity.Type, Opportunity.Case__c, 
                                                    Opportunity.AccountId, Opportunity.Name,Par_Impl_case_Id_Hide__c,Par_Impl_case_status_Hide__c,PDLJSON__c,IsRerate__c from OpportunityLineItem where //Decision_Status__c IN ('Sold', 'Not - Sold')  
                                                    //and 
                                                    opportunityId =: oppId];//13770  //commented for 3.1                  
                        Map<String,List<OpportunityLineItem>> mapGrpOLI = new Map<String,List<OpportunityLineItem>>();//13770
                        for(OpportunityLineItem oli : OLIListNew){
                            for(String grpNbr : reqGrpMap.keyset()){
                                P2EwService.QQContract reqCont = reqGrpMap.get(grpNbr);
                                if(oli.Group_Number__c==reqCont.GroupNumber){
                                    if(mapGrpOLI.get(reqCont.GroupNumber)==null || mapGrpOLI.get(reqCont.GroupNumber).size()==0){
                                        mapGrpOLI.put(reqCont.GroupNumber,new List<OpportunityLineItem>());
                                    }
                                    mapGrpOLI.get(reqCont.GroupNumber).add(oli);
                                }
                            }
                        }
                        Boolean isError=false;                                                                        
                        for(P2EwService.QQContract reqCont : req.Contract){                            
                            Integer bencount=0;
                            if((!mapGrpOLI.isEmpty() || mapGrpOLI!=null) && mapGrpOLI.get(reqCont.GroupNumber)!=null){
                                for(OpportunityLineItem oliDC:mapGrpOLI.get(reqCont.GroupNumber)){
                                    if((oliDC.Action__c=='Discontinue') || (oliDC.Decision_Status__c=='Not - Sold' && oliDC.Action__c=='New')){
                                        bencount++;
                                    }
                                }
                            }
                            for(P2EwService.QQBenefits reqBen : grpBenefitsMap.get(reqCont.GroupNumber)){
                                Boolean flag=true;
                                for(OpportunityLineItem oliDC:mapGrpOLI.get(reqCont.GroupNumber)){                                    
                                   if((reqCont.GroupTermDate!='' || reqCont.IsGroupTerminate==True) && bencount!=mapGrpOLI.get(reqCont.GroupNumber).size()){
                                       if(reqBen.PlanId==oliDC.product2.PlanID__c && oliDC.Action__c=='Discontinue'){
                                           errorList.add(new P2EwService.ServiceError('TERM ERROR INVALID DATE',reqBen.GroupCaseId));
                                           isError=true;
                                       } 
                                   }
                                   if((reqCont.GroupTermDate=='' || reqCont.IsGroupTerminate==False) && bencount==mapGrpOLI.get(reqCont.GroupNumber).size()){
                                       if(reqBen.PlanId==oliDC.product2.PlanID__c && oliDC.Action__c=='Discontinue' && oliDC.IsRerate__c){
                                           errorList.add(new P2EwService.ServiceError('SF002-RERATE ERROR','Rerate/Negotiation in progress'));
                                           isError=true;
                                           flag=false;
                                           break;
                                       }
                                       else if(reqBen.PlanId==oliDC.product2.PlanID__c && oliDC.Action__c=='Discontinue' && !oliDC.IsRerate__c){
                                           errorList.add(new P2EwService.ServiceError('TERM ERROR NO DATE',reqBen.GroupCaseId));
                                           isError=true;
                                       }                                      
                                   }                                      
                                }
                                if(flag==false){
                                    break;
                                }
                            }                                                        
                        }
                        if(isError){
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList); 
                        }*/ //till here for 13770  //commented for 3.1                         
                        /********************************************************************************/
                        if(reqCaseStatus=='Resolved-Completed'){
                        Map<String, Contract> grpContractMap = new Map<String, Contract>();
                        //Map<String, Boolean> grpMtvImpl = new Map<String, Boolean>();
                        
                       // Map<Id, List<Segmentation__c>> mpcntrtseg = new Map<Id, List<Segmentation__c>>();//geetha//commented for 3.1
                       // Map<String, List<Segmentation__c>> mpgrpnoseg = new Map<String, List<Segmentation__c>>();//geetha//commented for 3.1
                        //Segmentation__c cloneSegment = new Segmentation__c();//geetha //commented for 3.1
                        
                        //ProdSegment__c productSegmentClone = new ProdSegment__c();//geetha //commented for 3.1
                        //Contract Creation / Updation
                        /*List<Contract> ContractList = [select id, AccountId, Status, Name, Group_Number__c, MTV_Implemented__c, //commented for 3.1
                                                        StartDate, EndDate, ContractNumber, contractterm, Opportunity__c,Renewal_Opportunity__c,Renew_Oppty_Hide__c, 
                                                        Change_Opportunity__c, Opportunity__r.Type, Renewal_clause__c,Opportunity__r.Id,Change_Opportunity__r.Id  from Contract 
                                                        where Group_Number__c in: reqGrpMap.keySet() 
                                                        and (
                                                                (
                                                                    (
                                                                        (Opportunity__r.Type in ('New','Renewal') and EndDate =: oppEndDate) OR 
                                                                        (Change_Opportunity__r.Type = 'Change' and EndDate =: oppEndDate) //OR
                                                                        //(Opportunity__r.Id=:oppId or (Change_Opportunity__c!=null and Change_Opportunity__r.Id=:oppId)) 
                                                                        //Opportunity__r.Type in ('New','Renewal') 
                                                                    ) 
                                                                    
                                                                )
                                                                AND 
                                                                    (Status = 'Activated')                                                                
                                                            )];*/ //commented for 3.1
                        
                          //Added by Geetha JIRA 11660
                          /*List<Contract> ContractListNew = [select id, AccountId, Status, Name, Group_Number__c, MTV_Implemented__c, //commented for 3.1
                                                            StartDate, EndDate, ContractNumber, contractterm, Opportunity__c,Renewal_Opportunity__c,Renew_Oppty_Hide__c, 
                                                            Change_Opportunity__c, Opportunity__r.Type, Renewal_clause__c  from Contract 
                                                            where Group_Number__c in: reqGrpMap.keySet() 
                                                            and Status = 'Activated' and (Opportunity__r.Id=:oppId or (Change_Opportunity__c!=null and Change_Opportunity__r.Id=:oppId))]; //commented for 3.1
                         if(!mapGroupContract.isEmpty()){                                 
                             List<Contract> ContractListNew=mapGroupContract.values());
                         }                                   
                         //system.debug('ContractListNew'+ContractListNew);
                         List<ContractProduct__c> cntrtPrdList = new List<ContractProduct__c>();
                         Set<string> grpNo = new set<String>(); 
                         system.debug('reqGrpMap'+reqGrpMap); 
                         if(ContractListNew.size()>0 || ContractListNew!=null || !ContractListNew.isEmpty()){                     
                             for(String grpNbr : reqGrpMap.keyset()){
                                 system.debug('grpNbr'+grpNbr);
                                 P2EwService.QQContract reqCont = reqGrpMap.get(grpNbr);
                                 system.debug('reqCont'+reqCont);                                                                                                                                                                                 
                                     for(Contract cntrt : ContractListNew){
                                         system.debug('cntrt'+cntrt);
                                         if(cntrt.EndDate == date.valueOf(reqCont.ContractTermTo.subString(0,4)+'-'+reqCont.ContractTermTo.subString(4,6)+'-'+reqCont.ContractTermTo.subString(6,8)+' 00:00:00') && cntrt.Group_Number__c==grpNbr){// && (cntrt.Opportunity__r.Id==oppId || (cntrt.Change_Opportunity__c!=null && cntrt.Change_Opportunity__r.Id==oppId))){
                                             system.debug('into if line 406');
                                             grpNo.add(grpNbr);
                                             system.debug('grpNo'+grpNo);
                                             system.debug('reqGrpProdIdMap'+reqGrpProdIdMap);
                                             for(Id prodId : reqGrpProdIdMap.get(grpNbr)){                                             
                                                 ContractProduct__c conPro = new ContractProduct__c();
                                                 conPro.Contract__c = cntrt.Id;
                                                 conPro.Product__c = prodId;
                                                 cntrtPrdList.add(conPro); 
                                             }                                        
                                         }                                                                      
                                     }
                             }
                             system.debug('cntrtPrdList'+cntrtPrdList);
                             if(cntrtPrdList!=null || !cntrtPrdList.isEmpty()){
                                 upsert cntrtPrdList;
                             }
                        }*/ //commented for 3.1                        
                        /*for(Contract cont : ContractList){ //commented for 3.1
                          if(grpContractMap.get(cont.Group_Number__c) == null && !cont.MTV_Implemented__c){ //&& grpMtvImpl.get(cont.Group_Number__c)==null)  
                                grpContractMap.put(cont.Group_Number__c, cont);
                          }
                          cntrtId.add(cont.Id);  //geetha
                        }*/ //commented for 3.1                                                                 
                        //Id contractRTId = P2EhUtility.getRecordTypeId('Contract', 'Contract With IAC');//commented for 3.1
                        //Contract newCont;
                        
                       /* if(cntrtId.size()>0 || cntrtId!=null || !cntrtId.isEmpty()){//commented for 3.1
                            List<Segmentation__c> segList = Database.Query(P2EhUtility.getQuery('Segmentation__c') + 'Where Contract__c in: cntrtId');// geetha
                            system.debug('segList:::' + segList);
                                                    
                            for(Segmentation__c seg : segList){
                                if(mpcntrtseg.get(seg.contract__c)==null){
                                    mpcntrtseg.put(seg.contract__c,new List<Segmentation__c>());
                                }
                                mpcntrtseg.get(seg.contract__c).add(seg);
                            }
                            system.debug('mpcntrtseg:::' + mpcntrtseg);
                            
                            
                            for(Segmentation__c seg : segList){
                                if(mpgrpnoseg.get(seg.Group_Number__c)==null){
                                    mpgrpnoseg.put(seg.Group_Number__c,new List<Segmentation__c>());
                                }
                                mpgrpnoseg.get(seg.Group_Number__c).add(seg);
                            }//geetha
                            system.debug('mpgrpnoseg:::' + mpgrpnoseg);
                        }*/ //commented for 3.1
                                                                  
                        
                            /*Contract newCont; //13770//commented for 3.1
                            Date cntrtTermDate;//13770
                            if(reqCont.GroupTermDate!=''){
                                cntrtTermDate = date.valueOf(reqCont.GroupTermDate.subString(0,4)+'-'+reqCont.GroupTermDate.subString(4,6)+'-'+reqCont.GroupTermDate.subString(6,8)+' 00:00:00');//13770
                            }
                            Integer oliCount=0;//13770
                            if(((!grpBenefitsMap.isEmpty() || grpBenefitsMap!=null) && (!mapGrpOLI.isEmpty() || mapGrpOLI!=null)) && grpBenefitsMap.get(grpNbr)!=null && mapGrpOLI.get(grpNbr)!=null){                                        
                                for(OpportunityLineItem oli:mapGrpOLI.get(reqCont.GroupNumber)){
                                    for(P2EwService.QQBenefits reqBen : grpBenefitsMap.get(grpNbr)){
                                        if(reqBen.PlanId == oli.product2.PlanID__c && oli.Action__c == 'Discontinue'){                                          
                                              oliCount++;
                                        }
                                    }
                                } 
                            }*/ //Till here for 13770 //commented for 3.1
                                                       
                                /*if((reqCont.GroupTermDate!='' && reqCont.IsGroupTerminate==True && cntrtTermDate<=System.today())){//13770   //commented for 3.1                                                                                                                                                                                                                                                 
                                       isOpptyToCreate = false;
                                       cont.Status = 'Terminated';
                                       cont.Group_Term_Date__c = cntrtTermDate;
                                       cont.Renewal_Opportunity__c = null;
                                       contractsToUpsert.add(cont);                                                                                           
                                }*/ //till here for 13770 //commenetd for 3.1
                                
                                /*else if((reqCont.GroupTermDate=='' && reqCont.IsGroupTerminate==False && oliCount!=grpBenefitsMap.get(grpNbr).size())||(reqCont.GroupTermDate!='' && reqCont.IsGroupTerminate==True && cntrtTermDate>System.today())){//added for 13770 //commented for 3.1
                                    //newCont = frameContract(null, 'Draft', accId, oppId, contractRTId, oppName, reqCont, oppType);//oppType added by Geetha for PC-13726 on Nov 18
                                    newCont = findExistingGroup(reqCont.GroupNumber, oppId, oppType); 
                                    if(newCont == null){
                                        errorList.add(new P2EwService.ServiceError('SF002-111','Group is not configured in the system, please configure the Group first or contact administrator.'));
                                        system.debug('newCont  :::' + newCont);
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                    
                                    if(oppType == 'Change'){
                                        if(reqCaseStatus=='Resolved-Completed'){
                                                cont.Status = 'Changed';
                                                cont.Renew_Oppty_Hide__c = cont.Renewal_Opportunity__c;
                                                cont.Renewal_Opportunity__c = null;
                                                newCont.Opportunity__c = cont.Opportunity__c;
                                                newCont.Change_Opportunity__c = oppId;
                                        }
                                    }else{
                                        system.debug('line 370 else condition');
                                        cont.Status = 'Renewed';
                                    }                                    
                                    contractsToUpsert.add(cont);
                               }
                               else{
                                   isOpptyToCreate = false;
                               }
                            }else if(grpContractMap.get(grpNbr)==null && reqCont.GroupTermDate=='' && reqCont.IsGroupTerminate==False && oliCount!=grpBenefitsMap.get(grpNbr).size()) {//13770
                                //newCont = frameContract(null, 'Draft', accId, oppId, contractRTId, oppName, reqCont, oppType);//oppType added by Geetha for PC-13726 on March 1, 2017
                                newCont = findExistingGroup(reqCont.GroupNumber, oppId, oppType); 
                                if(newCont == null){
                                    errorList.add(new P2EwService.ServiceError('SF002-111','Group is not configured in the system, please configure the Group first or contact administrator.'));
                                    system.debug('newCont  :::' + newCont);
                                    Database.rollback(sp);
                                    return new P2EwService.SF001Response('Error', errorList);
                                }
                            }
                            if(newCont!=null){
                                contractsToUpsert.add(newCont);
                            }                            
                        }*/ //commented for 3.1
                    
                    for(String grpNbr : reqGrpMap.keyset()){                            
                        P2EwService.QQContract reqCont = reqGrpMap.get(grpNbr);
                        //3.1 Start
                        if(mapGroupContract.get(grpNbr) != null){    
                            Contract cont = mapGroupContract.get(grpNbr);                                    
                            system.debug('Contract###'+cont);                            
                            if(oppType == 'Change'){
                                /*if(cont.Status=='Draft'){
                                    if(!mapGroupMasterContract.isEmpty() && mapGroupMasterContract.containsKey(grpNbr)){
                                        if(mapGroupMasterContract.get(grpNbr).Opportunity__c!=null){
                                            cont.Opportunity__c=mapGroupMasterContract.get(grpNbr).Opportunity__c;
                                        }
                                        else{
                                            cont.Opportunity__c=oppId;
                                        } 
                                        mapGroupMasterContract.get(grpNbr).Sales_Status__c='Changed';
                                        mapGroupMasterContract.get(grpNbr).Renew_Oppty_Hide__c=mapGroupMasterContract.get(grpNbr).Renewal_Opportunity__c;
                                        mapGroupMasterContract.get(grpNbr).Renewal_Opportunity__c = null;                                         
                                    }
                                                                       
                                }*/
                                if(cont.Status=='Activated'){
                                    if(!mapGrpGroupInfoHistoryLatestList.isEmpty() && mapGrpGroupInfoHistoryLatestList.containsKey(grpNbr) && mapGrpGroupInfoHistoryLatestList.get(grpNbr).size()>0){
                                        for(Group_Info_History__c gih:mapGrpGroupInfoHistoryLatestList.get(grpNbr)){
                                            if(gih.update_type__c=='Change' && gih.status__c=='Activated' && gih.Sales_Status__c!='Changed'){
                                                gih.Sales_Status__c='Changed';
                                                gih.Renew_Oppty_Hide__c=gih.Renewal_Opportunity__c;
                                                gih.Renewal_Opportunity__c = null;
                                                gihListToUpdate.add(gih);
                                                if(gih.Opportunity__c!=null){
                                                    cont.Opportunity__c=gih.Opportunity__c;
                                                }
                                            }
                                        }
                                        if(cont.Opportunity__c==null){
                                            cont.Opportunity__c=OppId;
                                        }
                                    }
                                    cont.Change_Opportunity__c=oppId;
                                }
                                                                                               
                            }
                            else if(oppType=='Renewal'){
                                /*if(cont.Status=='Draft'){
                                    if(!mapGroupMasterContract.isEmpty() && mapGroupMasterContract.containsKey(grpNbr)){
                                        mapGroupMasterContract.get(grpNbr).Sales_Status__c='Renewed';                                           
                                    }
                                    if(cont.change_opportunity__c!=null){
                                        cont.change_opportunity__c=null;
                                    }    
                                }*/
                                if(cont.Status=='Activated'){
                                    system.debug('into contract status Activated if');
                                    system.debug('mapGrpGroupInfoHistoryLatestList'+mapGrpGroupInfoHistoryLatestList);
                                    if(!mapGrpGroupInfoHistoryLatestList.isEmpty() && mapGrpGroupInfoHistoryLatestList.containsKey(grpNbr) && mapGrpGroupInfoHistoryLatestList.get(grpNbr).size()>0){
                                        system.debug('into mapGrpGroupInfoHistoryLatestList if');
                                        for(Group_Info_History__c gih:mapGrpGroupInfoHistoryLatestList.get(grpNbr)){
                                            if((gih.update_type__c=='Renewal' || gih.update_type__c=='Extension') && gih.Sales_Status__c!='Renewed' && gih.status__c=='Activated'){
                                                system.debug('gih update if');
                                                gih.Sales_Status__c='Renewed';
                                                gihListToUpdate.add(gih);
                                            }                                           
                                        }
                                    }
                                    if(cont.change_opportunity__c!=null){
                                        cont.change_opportunity__c=null;
                                    }
                                    cont.Opportunity__c=OppId;
                                }
                                
                            }
                            else{
                                if(cont.Status=='Activated'){
                                    cont.Opportunity__c=OppId;
                                }
                            }
                            contractsToUpsert.add(cont);
                        }
                    }
                    
                    if(gihListToUpdate.size()>0){
                        try{
                            update gihListToUpdate;
                            system.debug('gihListToUpdate'+gihListToUpdate);
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-100','Service Call Failed. Contact Administrator.'));
                            system.debug('gihListToUpdate upsert Failed :::' + gihListToUpdate);
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        //system.debug('contractsToUpsert ::::'+contractsToUpsert);                        
                        for(Group_Info_History__c gih:gihListToUpdate){
                            if(!mapGrpGIHUpdated.containsKey(gih.Group_Number__c)){
                                mapGrpGIHUpdated.put(gih.Group_Number__c,gih);
                            }
                        }
                    }
                    /*if(!mapGroupMasterContract.isEmpty()){
                        try{
                            update mapGroupMasterContract.values();
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-100','Service Call Failed. Contact Administrator.'));
                            system.debug('mapGroupMasterContract upsert Failed :::' + mapGroupMasterContract.values());
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        //system.debug('contractsToUpsert ::::'+contractsToUpsert);
                    }*/
                    //3.1 End
                    if(contractsToUpsert.size()>0){
                        try{
                            update contractsToUpsert;
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-100','Service Call Failed. Contact Administrator.'));
                            system.debug('contractsToUpsert upsert Failed :::' + contractsToUpsert);
                            system.debug(e.getMessage());
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        system.debug('contractsToUpsert ::::'+contractsToUpsert);
                    }

                        /*if(cntrtId.size()>0 || cntrtId!=null || !cntrtId.isEmpty()){//commented for 3.1
                            for(Contract cntrt1 : ContractList){//geetha
                                
                                    if(mpcntrtseg.get(cntrt1.Id)!=null){
                                        system.debug('line 468 in if');                   
                                        for(Segmentation__c segment : mpcntrtseg.get(cntrt1.Id)){
                                            segId.add(segment.Id);
                                        }
                                    }
                                
                            }
                            system.debug('segId:::' + segId);
                            Set<Id> prodIdsSet = new set<Id>();//14083
                            for(set<Id> pidset:reqGrpProdIdMap.values()){
                                prodIdsSet.addAll(pidset);
                            } //Till here for 14083                            
                            List<ProdSegment__c> prodSegList = Database.Query(P2EhUtility.getQuery('ProdSegment__c')+ 'Where Segmentation__c in: segId AND IS_Active__c=true AND Product__c in:prodIdsSet');//"IS_Active__c=true" added for PC-14145, Product__c in:prodIdsSet added for PC-14083
                            system.debug('prodSegList :::' + prodSegList);
                             if(prodSegList!=null){//Added by Geetha for 13886
                                mapProdIdNewRSId = FunctionRateSheetWithProdSegment(prodSegList); //Add by Parthiban 21-09-2016
                            }//13886                               
                            List<Segmentation__c> insertSeg = new List<Segmentation__c>();
                            List<Segmentation__c> updateSeg = new List<Segmentation__c>();
                            for(Contract cntrt : contractsToUpsert){
                                for(Contract cntrt1 : ContractList){
                                    system.debug('mpcntrtseg.get(cntrt1.Id):::' + mpcntrtseg.get(cntrt1.Id));
                                    system.debug('cntrt.Group_Number__c :::' + cntrt.Group_Number__c);
                                    system.debug('cntrt1.Group_Number__c :::' + cntrt1.Group_Number__c);
                                    system.debug('cntrt.Status :::' + cntrt.Status);
                                    //if(cntrt1.EndDate==oppEndDate) {                                   
                                        if(mpcntrtseg.get(cntrt1.Id)!=null && cntrt.Group_Number__c == cntrt1.Group_Number__c && cntrt.Status == 'Draft'){
                                            system.debug('line 476 in if');                   
                                            for(Segmentation__c segment : mpcntrtseg.get(cntrt1.Id)){                                            
                                                cloneSegment = segment.clone();
                                                cloneSegment.Old_Segment_Id__c = segment.Id;
                                                cloneSegment.Contract__c = cntrt.Id;
                                                cloneSegment.End_Date__c = cntrt.EndDate;
                                                cloneSegment.Status__c = cntrt.Status;
                                                cloneSegment.Effective_Date__c = cntrt.StartDate;
                                                insertSeg.add(cloneSegment);
                                            }
                                        }
                                        if(mpcntrtseg.get(cntrt1.Id)!=null && cntrt.Group_Number__c == cntrt1.Group_Number__c && (cntrt.Status == 'Renewed' || cntrt.Status == 'Changed')){
                                            system.debug('line 504 in if');                   
                                            for(Segmentation__c segment : mpcntrtseg.get(cntrt1.Id)){ 
                                                segment.Status__c = cntrt.Status;
                                                updateSeg.add(segment);
                                            }
                                        }
                                    //}    
                                }
                            }
                            if(updateSeg.size()>0){
                                try{
                                    update updateSeg;
                                }catch(Exception e){
                                    errorList.add(new P2EwService.ServiceError('SF002-104','Service Call Failed. Contact Administrator.'));
                                    system.debug('updateSeg update Failed :::' + updateSeg);
                                    system.debug(e.getMessage());
                                    Database.rollback(sp);
                                    return new P2EwService.SF001Response('Error', errorList);
                                }
                            }
                            system.debug('updateSeg:::' + updateSeg);
                            
                            if(insertSeg.size()>0){
                                try{
                                    insert insertSeg;
                                }catch(Exception e){
                                    errorList.add(new P2EwService.ServiceError('SF002-102','Service Call Failed. Contact Administrator.'));
                                    system.debug('insertSeg insert Failed :::' + insertSeg);
                                    system.debug(e.getMessage());
                                    Database.rollback(sp);
                                    return new P2EwService.SF001Response('Error', errorList);
                                }
                                system.debug('insertSeg :::' + insertSeg);
                                
                                List<ProdSegment__c> insertProdSegList = new List<ProdSegment__c>();                           
                                
                               List<ProdSegment__c> prodSegListToUpdate = new List<ProdSegment__c>();
                               
                             for(ProdSegment__c prodseg : prodSegList){
                                   for(Segmentation__c seg : insertSeg){
                                       if(prodseg.Segmentation__c == seg.Old_Segment_Id__c){
                                           if((!mapProdIdNewRSId.isempty() || mapProdIdNewRSId!=null) && mapProdIdNewRSId.get(prodseg.Product__c)!=null){//13886
                                               for(Id RSId: mapProdIdNewRSId.get(prodseg.Product__c)){
                                                   system.debug('prodseg.Segmentation__c:::' + prodseg.Segmentation__c);
                                                   system.debug('seg.Old_Segment_Id__c:::' + seg.Old_Segment_Id__c);                                               
                                                   system.debug('inside if line 518');
                                                   productSegmentClone =  prodseg.clone();
                                                   productSegmentClone.Segmentation__c = seg.Id;
                                                   productSegmentClone.RateSheet__c = RSId;                                                   
                                                   productSegmentClone.Is_Active__c = true;
                                                   insertProdSegList.add(productSegmentClone);
                                                }
                                                prodseg.Is_Active__c = false;
                                                prodSegListToUpdate.add(prodseg);
                                            }//13886
                                        }
                                   }
                                   
                               }
                               if(insertProdSegList.size()>0){
                                   try{
                                        insert insertProdSegList;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-103','Service Call Failed. Contact Administrator.'));
                                        system.debug('insertProdSegList insert Failed :::' + insertProdSegList);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                               }
                               if(prodSegListToUpdate.size() > 0){
                                   try{
                                        update prodSegListToUpdate;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-103','Service Call Failed. Contact Administrator.'));
                                        system.debug('updateProdSegList update Failed :::' + prodSegListToUpdate);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }                                   
                               }
                               system.debug('insertProdSegList:::' + insertProdSegList); 
                           } //geetha
                       }
                       
                       
                                                  
                        //Update grpContractMap
                        if(grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null){
                            grpContractMap.clear();
                            List<Contract> updCont = Database.Query(P2EhUtility.getQuery('Contract') + ' Where Id in: contractsToUpsert');
                            for(Contract cont : updCont){
                                if(grpContractMap.get(cont.Group_Number__c) == null && (cont.Status == 'Draft' || cont.Status == 'Activated') ){
                                
                                    grpContractMap.put(cont.Group_Number__c, cont);
                                }
                            }
                        
                            
                        }
                        }*/ //commented for 3.1
                        
                        //3.1 Start
                        set<Id> cntrtId = new set<Id>(); //geetha
                        set<Id> segId = new Set<Id>();//geetha
                        Set<Id> prodIdsSet = new set<Id>();//14083
                        for(set<Id> pidset:reqGrpProdIdMap.values()){
                            prodIdsSet.addAll(pidset);
                        } //Till here for 14083
                        system.debug('3.1 contractstoupsert'+contractsToUpsert);
                        if(grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null){
                            grpContractMap.clear();
                        }
                        for(Contract cntrt:contractsToUpsert){
                            cntrtId.add(cntrt.Id);                            
                            if(!grpContractMap.containsKey(cntrt.Group_Number__c)){
                                grpContractMap.put(cntrt.Group_Number__c, cntrt);                                    
                            }
                        }
                        system.debug('3.1 grpContractMap'+grpContractMap);
                        List<Segmentation__c> segList = Database.Query(P2EhUtility.getQuery('Segmentation__c') + 'Where Contract__c in: cntrtId');// geetha
                        for(Segmentation__c seg:segList){
                            segId.add(seg.Id);
                        }
                        List<ProdSegment__c> prodSegList = Database.Query(P2EhUtility.getQuery('ProdSegment__c')+ 'Where Segmentation__c in: segId AND IS_Active__c=true AND Product__c in:prodIdsSet');//"IS_Active__c=true" added for PC-14145, Product__c in:prodIdsSet added for PC-14083 
                        if(prodSegList.size()>0){
                            mapProdIdNewRSId = FunctionRateSheetWithProdSegment(prodSegList); //Add by Parthiban 21-09-2016             
                            for(ProdSegment__c prdSeg:prodSegList){
                                if((!mapProdIdNewRSId.isempty() || mapProdIdNewRSId!=null) && mapProdIdNewRSId.get(prdSeg.Product__c)!=null){//13886
                                    for(Id RSId: mapProdIdNewRSId.get(prdSeg.Product__c)){
                                        prdSeg.RateSheet__c = RSId;
                                    }
                                }
                            }
                            update prodSegList;
                        }    
                        //3.1 End    
                        
                        /********************************************************************************/
                        
                        set<Id> ProdIds = new set<Id>();
                        for(OpportunityLineItem oli : OLILIST){
                            ProdIds.add(oli.Product2Id);    
                        }
                        //Map<Id,set<Id>> mapcntprd=new Map<Id,set<Id>>();
                        List<ContractProduct__c> ConProLst = [Select Id,Contract__c,Product__c from ContractProduct__c where contract__c in: cntrtId];
                        /*if(ConProLst.size()>0){
                            for(ContractProduct__c cpd:ConProLst){
                                if(!mapcntprd.containsKey(cpd.contract__c)){
                                    mapcntprd.put(cpd.contract__c,new set<Id>());
                                }
                                mapcntprd.get(cpd.contract__c).add(cpd.product__c);
                            }
                        }*/
                        if(ConProLst.size()>0){
                            delete ConProLst;
                        }
                        Map<String, Contract> updGrpNbrContract = new Map<String, Contract>();
                        Boolean prodChanged = false;
                        List<Product2> prods = [Select Id, Related_Contract__c, Delivery_Method__c,PlanID__c from Product2 Where Id in: ProdIds];
                        
                       /*** Added by Murali for Missing BP Solution(PC-15498)- Start ***/
                       Map<Id, String> ProdIdGroupPlanMap = new Map<Id, String>();
                       Map<Id, Set<String>> ProdIdBPIdMap = new Map<Id, Set<String>>();
                       Map<Id, Set<String>> ProdIdBPIdMapDataBase = new Map<Id, Set<String>>();// Geetha PC-15498
                       Map<String, Id> mapBenpackBenId = new Map<String, Id>();// Geetha PC-15498
                        Map<String, Id> planIdProdIdMap = new Map<String, Id>();
                        Set<String> unWantedBpIdSet=new set<String>();//Geetha PC-15498
                        List<Benefit_Package__c> benPackLstToInsert = new List<Benefit_Package__c>();// Geetha PC-15498
                        List<ProdBenefit__c> prdBenLstToInsert = new List<ProdBenefit__c>();// Geetha PC-15498
                        try{
                            for(Product2 prd:prods){
                                planIdProdIdMap.put(prd.PlanID__c,prd.Id);
                            }
                            for(String planId: reqPlanIdGroupPlanMap.keyset()){
                                if(planIdProdIdMap.containsKey(planId)){
                                    ProdIdGroupPlanMap.put(planIdProdIdMap.get(planId),reqPlanIdGroupPlanMap.get(planId));
                                    ProdIdBPIdMap.put(planIdProdIdMap.get(planId),reqPlanIdBPIdMap.get(planId));                               
                                }
                            }
                                                       
                            system.debug('ProdIdBPIdMap'+ProdIdBPIdMap);
                            /*** Geetha PC-15498 ***/
                            List<Benefit_Package__c> benPackLst = [select id,Benefit_Package_ID__c from Benefit_Package__c where Benefit_Package_ID__c in: allBPIdSet];
                            system.debug('benPackLst:::' + benPackLst);
                            if(benPackLst.size()>0){ 
                                for(Benefit_Package__c benPack:benPackLst){
                                    unWantedBpIdSet.add(benPack.Benefit_Package_ID__c.toUpperCase());
                                }
                            }    
                            
                            system.debug('unWantedBpIdSet:::' + unWantedBpIdSet);               
                            for(String benPackId:allBPIdSet){
                                if((unWantedBpIdSet.size()>0 && !unWantedBpIdSet.contains(benPackId)) || unWantedBpIdSet.size()==0){
                                  Benefit_Package__c benPackIns = new Benefit_Package__c();
                                  benPackIns.Benefit_Package_ID__c=benPackId;
                                  benPackLstToInsert.add(benPackIns);
                                }
                            }
                            if(benPackLstToInsert.size()>0){             
                                insert benPackLstToInsert;                                
                            }
                            benPackLst.addAll(benPackLstToInsert);
                            
                            //3.1 Start
                            set<Id> benId=new set<Id>();
                            List<GroupBenefit__c> grpBenToInsertList = new List<GroupBenefit__c>(); 
                            for(Benefit_Package__c benpac:benPackLst){
                                benId.add(benpac.Id);
                            }
                            Map<Id,set<String>> mapGrpGroupBenefit =new Map<Id,set<String>>();   
                            List<GroupBenefit__c> grpBenList = [select id,Benefit_Package__c,Benefit_Package__r.Benefit_Package_ID__c,Group_Info__c,Group_Info__r.Group_Number__c,Group_Info__r.Id,isCurrent__c,isManual__c from GroupBenefit__c where Group_Info__c in:cntrtId and Benefit_Package__c in:benId];
                            for(GroupBenefit__c gb:grpBenList){
                                gb.isCurrent__c = true;
                                gb.isManual__c = false;
                                grpBenToInsertList.add(gb);
                                if(!mapGrpGroupBenefit.containsKey(gb.Group_Info__r.Id)){
                                    mapGrpGroupBenefit.put(gb.Group_Info__r.Id,new set<String>());
                                }
                                mapGrpGroupBenefit.get(gb.Group_Info__r.Id).add(gb.Benefit_Package__r.Benefit_Package_ID__c.toUpperCase());
                            }
                            for(Contract cont: grpContractMap.values()){
                                for(Benefit_Package__c benpac:benPackLst){
                                    if((!grpBenpackIdMap.isEmpty() && grpBenpackIdMap.containsKey(cont.Group_Number__c) && grpBenpackIdMap.get(cont.Group_Number__c).size()>0 && grpBenpackIdMap.get(cont.Group_Number__c).contains(benpac.Benefit_Package_ID__c.toUpperCase())) && ((!mapGrpGroupBenefit.isEmpty() && mapGrpGroupBenefit.containsKey(cont.Id) && mapGrpGroupBenefit.get(cont.Id).size()>0 && !mapGrpGroupBenefit.get(cont.Id).contains(benpac.Benefit_Package_ID__c.toUpperCase()))||mapGrpGroupBenefit.isEmpty() || (!mapGrpGroupBenefit.isEmpty() && mapGrpGroupBenefit.containsKey(cont.Id) && mapGrpGroupBenefit.get(cont.Id).size()==0) || (!mapGrpGroupBenefit.isEmpty() && !mapGrpGroupBenefit.containsKey(cont.Id)))){
                                        GroupBenefit__c gb=new GroupBenefit__c();
                                        gb.Benefit_Package__c=benPac.Id;
                                        gb.Group_Info__c=cont.Id;
                                        gb.isCurrent__c=true;
                                        gb.isManual__c=false;
                                        grpBenToInsertList.add(gb);
                                    }
                                }
                            }
                            if(grpBenToInsertList.size()>0){
                                upsert grpBenToInsertList;
                            }
                            //3.1 End
                            
                            
                            for(Benefit_Package__c benPack1:benPackLst){
                               if(mapBenpackBenId.get(benPack1.Benefit_Package_ID__c)==null){
                                   mapBenpackBenId.put(benPack1.Benefit_Package_ID__c.toUpperCase(),benPack1.Id);
                                } 
                            }                            
                            List<ProdBenefit__c> prdBenLst = [select id,Benefit_Package__c,Benefit_Package__r.Benefit_Package_ID__c,Product__c,Benefit_Package__r.Id from ProdBenefit__c where Product__c in:ProdIds];//Geetha PC-15498
                            system.debug('prdBenLst:::' + prdBenLst);
                            if(prdBenLst.size()>0){                            
                                for(ProdBenefit__c prdBen:prdBenLst){
                                    if(!ProdIdBPIdMapDataBase.containsKey(prdBen.Product__c)){
                                       ProdIdBPIdMapDataBase.put(prdBen.Product__c,new set<string>());
                                    }
                                    if(prdBen.Benefit_Package__c!=null){
                                        ProdIdBPIdMapDataBase.get(prdBen.Product__c).add(prdBen.Benefit_Package__r.Benefit_Package_ID__c.toUpperCase()); 
                                    }                                
                                }
                            }    
                            system.debug('prods:::' + prods);  
                            system.debug('ProdIdBPIdMapDataBase:::' + ProdIdBPIdMapDataBase);  
                                                                                  
                            for(Product2 prd:prods){
                                if(ProdIdBPIdMap.get(prd.Id)!=null){
                                    for(String bpId:ProdIdBPIdMap.get(prd.Id)){
                                        system.debug('BPID List :::' + ProdIdBPIdMapDataBase.get(prd.Id));
                                        if((!ProdIdBPIdMapDataBase.isEmpty() && ProdIdBPIdMapDataBase.get(prd.Id)!=null && !ProdIdBPIdMapDataBase.get(prd.Id).contains(bpId))||ProdIdBPIdMapDataBase.isEmpty() || (!ProdIdBPIdMapDataBase.isEmpty() && ProdIdBPIdMapDataBase.get(prd.Id)==null)){
                                            ProdBenefit__c prdBenIns = new ProdBenefit__c();
                                            prdBenIns.Benefit_Package__c=mapBenpackBenId.get(bpId);                                            
                                            prdBenIns.Product__c=prd.Id;
                                            prdBenLstToInsert.add(prdBenIns);                                   
                                        }
                                    }
                                }
                            }
                            if(prdBenLstToInsert.size()>0){             
                                insert prdBenLstToInsert;
                            }                                    
                            /*** Geetha code end for PC-15498 ***/
                            
                           /*** PC-15498 End ***/
                        }catch(Exception e){
                            errorList.add(new P2EwService.ServiceError('SF002-103','Service Call Failed. Contact Administrator.'));                            
                            Database.rollback(sp);
                            return new P2EwService.SF001Response('Error', errorList);
                        }
                        
                        system.debug('grpContractMap' + grpContractMap);
                        List<ContractProduct__c> conProList = new List<ContractProduct__c>();
                        
                        /**Added for BP Solution (PC-15498) by Geetha START**/
                        if(grpContractMap.isEmpty() || grpContractMap.size()==0){
                            for(String grpNbr : reqGrpMap.keyset()){
                                //if(!grpNo.isEmpty() && grpNo.contains(grpNbr)){//commented for 3.1
                                    for(Product2 prod : prods){
                                        if(ProdIdGroupPlanMap.get(prod.Id)!=null && ProdIdGroupPlanMap.get(prod.Id)!=''){
                                            prod.GroupPlanName__c = ProdIdGroupPlanMap.get(prod.Id);
                                            prodChanged = true;
                                        }
                                    }
                                //}//commented for 3.1
                            }
                            if(prodChanged){
                                try{
                                    update prods;
                                }catch(Exception e){
                                    errorList.add(new P2EwService.ServiceError('SF002-220','Service Call Failed. Contact Administrator.'));
                                    system.debug('prods update failed :::' + prods);                                    
                                    system.debug(e.getMessage());
                                    Database.rollback(sp);
                                    return new P2EwService.SF001Response('Error', errorList);
                                }
                                    
                            }                        
                        } /**BP Solution by Geetha END**/
                        else if(grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null){
                            for(String grpNbr : reqGrpMap.keyset()){
                                if(reqGrpProdIdMap.get(grpNbr)!=null){ // && grpContractMap.get(grpNbr).Status == 'Activated')
                                    for(Id prodId : reqGrpProdIdMap.get(grpNbr)){
                                        for(Product2 prod : prods){
                                            if(prod.Id == prodId && grpContractMap.get(grpNbr) != null){
                                                prod.Group_Number__c = grpContractMap.get(grpNbr).Group_Number__c;
                                                prod.Group_Name__c = grpContractMap.get(grpNbr).Name;
                                                
                                                /*** Added by Murali for PC-15498 Start ***/
                                                if(ProdIdGroupPlanMap.get(prod.Id)!=null && ProdIdGroupPlanMap.get(prod.Id)!=''){
                                                    prod.GroupPlanName__c = ProdIdGroupPlanMap.get(prod.Id);
                                                    system.debug('GroupPlanName__c' + prod.GroupPlanName__c);
                                                }
                                                /*** PC-15498 End ***/
                                                //if((!mapcntprd.isEmpty() && mapcntprd.containsKey(grpContractMap.get(grpNbr).Id) && !mapcntprd.get(grpContractMap.get(grpNbr).Id).contains(prodId)) || mapcntprd.isEmpty() || (!mapcntprd.isEmpty() && !mapcntprd.containsKey(grpContractMap.get(grpNbr).Id))){
                                                    ContractProduct__c conPro = new ContractProduct__c();
                                                    conPro.Contract__c = grpContractMap.get(grpNbr).Id;
                                                    conPro.Product__c = prodId;
                                                    conProList.add(conPro);
                                                
                                                    grpContractMap.get(grpNbr).Product_Name__c = prod.Delivery_Method__c;
                                                    /*if(!mapcntprd.containsKey(grpContractMap.get(grpNbr).Id)){
                                                        mapcntprd.put(grpContractMap.get(grpNbr).Id,new set<Id>());
                                                    }
                                                    mapcntprd.get(grpContractMap.get(grpNbr).Id).add(prodId);*/
                                                //}
                                                updGrpNbrContract.put(grpNbr, grpContractMap.get(grpNbr));
                                                prodChanged = true;
                                            }
                                        }
                                    }
                                }
                            }
                        
                            if(prodChanged){
                                try{
                                    update prods;
                                    upsert conProList;
                                    system.debug('prods' + prods);
                                    system.debug(updGrpNbrContract.values());
                                    update updGrpNbrContract.values();
                                }catch(Exception e){
                                    errorList.add(new P2EwService.ServiceError('SF002-103','Service Call Failed. Contact Administrator.'));
                                    system.debug('conProList update failed :::' + conProList);
                                    system.debug('updGrpNbrContract.values() update failed :::' + updGrpNbrContract.values());
                                    system.debug(e.getMessage());
                                    Database.rollback(sp);
                                    return new P2EwService.SF001Response('Error', errorList);
                                }
                            }
                        }
                        /********************************************************************************/
                        // Insert New Contacts
                        if(reqNewContMap.size()>0){
                            Map<String, Contact> newContMap = new Map<String, Contact>();
                            for(String cntId : reqNewContMap.keyset()){
                                newContMap.put(cntId, frameContact(accId, reqNewContMap.get(cntId)));
                            }
                            
                            try{
                                insert newContMap.values();
                            }catch(Exception e){
                                errorList.add(new P2EwService.ServiceError('SF002-40','Service failed. Contact Administrator.'));
                                system.debug('newContMap.values() insert failed :::' + newContMap.values());
                                system.debug(e.getMessage());
                                Database.rollback(sp);
                                return new P2EwService.SF001Response('Error', errorList);
                            }
                            
                            system.debug('newContMap :: '+ newContMap);
                            system.debug('reqGrpNewCntMap :: ' + reqGrpNewCntMap);
                            
                            for(String grpNbr : reqGrpNewCntMap.keyset()){
                                for(String cntId : newContMap.keyset()){
                                    if(reqGrpNewCntMap.get(grpNbr).contains(cntId)){
                                        Set<Id> contIds;
                                        if(reqGrpCntIdMap.get(grpNbr)!=null){
                                            contIds = reqGrpCntIdMap.get(grpNbr);
                                        }else{
                                            contIds = new Set<Id>();
                                        }
                                        contIds.add(newContMap.get(cntId).Id);
                                        reqGrpCntIdMap.put(grpNbr, contIds);
                                    }
                                }
                            }
                            
                            //Associate Contract with Contact
                            system.debug('reqGrpCntIdMap @ CCR :: ' + reqGrpCntIdMap);
                            system.debug('grpContractMap :: ' + grpContractMap);
                            if(reqGrpCntIdMap.size()>0){
                                List<ContractContactRole> contrContToInsert = new List<ContractContactRole>();
                                System.debug('test_grpContractMap:' +grpContractMap);
                                if(grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null){
                                    for(String grpNbr : grpContractMap.keyset()){
                                        if(reqGrpCntIdMap.get(grpNbr)!=null){
                                            for(Id cntId : reqGrpCntIdMap.get(grpNbr)){
                                                if(grpContractMap.get(grpNbr) != null){
                                                    ContractContactRole contrCont = new ContractContactRole();
                                                    contrCont.ContractId = grpContractMap.get(grpNbr).Id;
                                                    contrCont.ContactId = cntId;
                                                    contrCont.Role = 'Renewal Recipient';
                                                    contrContToInsert.add(contrCont);
                                                }
                                            }
                                        }
                                    }
                                
                                    try{
                                        insert contrContToInsert;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-50','Service Call Failed. Contact Administrator.'));
                                        system.debug('contrContToInsert insert failed :::' + contrContToInsert);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                 }
                            }
                        }
                        
                        
                        /********************************************************************************/
                        // Creation of renewal Opportunities based on contract end dates and updating of contract.
                        
                        //if(isClosure){//reqCaseStatus!=null && (reqCaseStatus == 'Resolved-Completed' || reqCaseStatus.contains('Resolved'))
                            Set<String> grpNs;
                            List<Contract> lcont = new List<contract>();
                            if(reqDateGrpsMap.size()>0){
                                grpNs = new Set<String>();
                                for(Date endDate : reqDateGrpsMap.keyset()){//updated for 3.1
                                    grpNs.addAll(reqDateGrpsMap.get(endDate));//updated for 3.1
                                }
                                if(grpNs.size()>0){
                                    lcont = [select id, Group_Number__c,AccountId, status,Acc_Manager_Email__c,EndDate, Opportunity__c, Current_Delta_Primary_Enrollees__c,Renewal_Opportunity__c,Renew_Oppty_Hide__c,Product_Name__c from Contract where Group_Number__c in: grpNs];
                                }
                            }
                            /*Map<String, Contract> activeGrp = new Map<String, Contract>();//commented for 3.1
                            Map<String, Contract> termContMap = new Map<String, Contract>();//commented for 3.1
                            for(Contract termCont : [select id, Group_Number__c, EndDate from Contract where Group_Number__c in: grpContractMap.keyset() and Status = 'Changed' order by LastModifiedDate DESC]){
                                    if(termContMap.get(termCont.Group_Number__c) == null){
                                        termContMap.put(termCont.Group_Number__c, termCont);
                                    }
                            }
                            for(Contract cont : [select id, Group_Number__c, Opportunity__c, Renewal_Opportunity__c,Renew_Oppty_Hide__c from Contract where Group_Number__c in: grpNs and Status = 'Changed' Order by EndDate DESC]){
                                    if(activeGrp.get(cont.Group_Number__c)==null){
                                        activeGrp.put(cont.Group_Number__c, cont);
                                    }
                            }*/ //commented for 3.1 
                            
                            List<Opportunity> renOppToInsert = new List<Opportunity>();
                            Map<Date, Opportunity> dateOppMap = new Map<Date, Opportunity>();//updated for 3.1
                            Opportunity originOpp = Database.Query(P2EhUtility.getQuery('Opportunity') + 'Where id =: oppId Limit 1');
                            system.debug('line 593'+originOpp);
                            if(originOpp.type=='Change')
                            {
                                try{
                                    Id renOppId = originOpp.Renewal_Opportunity__c;
                                    Case CTU  = [select id,Status,Related_Opportunity__r.Id,Change_Type__c,Change_SubType__c from case where Related_Opportunity__r.Id =: renOppId AND Change_Type__c =: originOpp.Change_Type__c AND Change_SubType__c =: originOpp.Change_SubType__c AND Status NOT IN ('Closed','Resolved-Completed','Withdrawn') Limit 1];
                                    system.debug('line 598'+CTU);
                                    CTU.Status = 'Resolved-Completed';
                                    update CTU;
                                }
                                Catch(Exception e){
                                    system.debug(e.getMessage());
                                }
                            }
                            
                            //Added for 2-way Communication
                            List<Credit__c> orgCreditList = [SELECT Id,Name,Account__c,Frequency__c,Granted_Amount__c,Opportunity__c,PEPM_or_Dollar__c,Requested_Amount__c,Status__c,Type_of_Credit__c FROM Credit__c Where Opportunity__c=:originOpp.Id];
                            for(Credit__c cr:orgCreditList){
                                cr.Status__c = 'Activated';
                            }                            
                            if(orgCreditList.size()>0){
                                update orgCreditList;
                            }//Till Here
                            
                            //Account acc = Database.Query(P2EhUtility.getQuery('Account') + 'Where id =: accId Limit 1');
                            if(!reqDateGrpsMap.isEmpty()){
                                for(Date endDate : reqDateGrpsMap.keyset()){//updated for 3.1
                                    //Set<String> grpNs1 = new Set<String>();
                                    //grpNs1.addAll(reqDateGrpsMap.get(endDateStr));
                                    //Date endDat = date.valueOf(endDateStr.subString(0,4)+'-'+endDateStr.subString(4,6)+'-'+endDateStr.subString(6,8)+' 00:00:00');//commented for 3.1
                                    //lcont = [select id, Group_Number__c, status,Product_Name__c,Acc_Manager_Email__c, Opportunity__c, Current_Delta_Primary_Enrollees__c,Renewal_Opportunity__c from Contract where Group_Number__c in: grpNs1];
                                    Boolean bool = true;
                                    for(String grpNbr : reqDateGrpsMap.get(endDate)){//updated for 3.1
                                        /*if((termContMap.keyset().contains(grpNbr) && termContMap.get(grpNbr).EndDate == endDate) || ((grpContractMap.isEmpty() || grpContractMap==null) && oppType!='New') || ((!grpContractMap.isEmpty() || grpContractMap!=null) && isOpptyToCreate==false)){//Last two conditions added for 13770//commented for 3.1
                                            bool = false;
                                        }*/ //commented for 3.1
                                        
                                        if((!mapGrpGIHUpdated.isEmpty() && mapGrpGIHUpdated.containsKey(grpNbr) && mapGrpGIHUpdated.get(grpNbr).Sales_status__c=='Changed')){
                                            bool=false;
                                        }
                                    }
                                    
                                    system.debug('bool ::' + bool);
                                    
                                    if(!bool){
                                        continue;
                                    }
                                    Opportunity renOpp = originOpp.clone();
                                    renOpp.RenewOppName__c = 'Renewal Opportunity - ';
                                    for(String grpNbr : reqDateGrpsMap.get(endDate)){//updated for 3.1
                                        if((grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null) && grpContractMap.get(grpNbr)!=null){
                                            renOpp.RenewOppName__c += grpContractMap.get(grpNbr).contractNumber + ': ';
                                        }
                                    }
                                    renOpp.RenewOppName__c = renOpp.RenewOppName__c.removeEnd(': ');
                                    
                                    renOpp.RecordTypeID = P2EhUtility.getRecordTypeId('Opportunity', 'Renewal Opportunity');
                                    renOpp.Type ='Renewal';
                                    renOpp.AutoRenewal__c = true;
                                    renOpp.CloseDate = endDate + 1; 
                                    renOpp.Opportunity_Close_Date__c = null; // Added for PC-13989                                
                                    renOpp.StageName = Label.Sales_Stages_Retention_Activity; // Changed for Sales Stage - Sujit
                                    renOpp.Workflow_Stage__c = Label.Sales_Stages_Retention_Activity;
                                    renOpp.ForecastCategoryName = 'Pipeline';
                                    renOpp.Probability = 75;
                                    renOpp.Contract_End_Date__c = endDate;
                                    renOpp.Type_of_Credits__c = null;
                                    renOpp.Audit_Credits_Type__c = null;
                                    renOpp.Audit_Credits__c = null;
                                    renOpp.Audit_Credits_Granted__c = null;
                                    renOpp.Audit_credit_frequency__c = null;
                                    renOpp.Implementation_Credit_Type__c = null;
                                    renOpp.Implementation_Credits__c = null;
                                    renOpp.Implementation_Credits_Granted__c = null;
                                    renOpp.Implementation_Credit_Frequency__c = null;
                                    renOpp.Communication_Credit_Type__c = null;
                                    renOpp.Communication_Credits__c = null;
                                    renOpp.Communication_Credits_Granted__c = null;
                                    renOpp.Communication_Credit_Frequency__c = null;
                                    renOpp.Other_Credits_Type__c = null;
                                    renOpp.Other_Credit__c = null;
                                    renOpp.Other_Credits_Granted__c = null;
                                    renOpp.Other_Credits_Frequency__c = null;
                                    renOpp.Note_for_Other_Credit__c = null;
                                    renOpp.Priority_1__c = null;
                                    renOpp.Priority_2__c = null;
                                    renOpp.Priority_3__c = null;
                                    renOpp.Priority_4__c = null;
                                    renOpp.Priority_5__c = null;
                                    renOpp.Strategic_Pricing_Recommendations__c = null;
                                    renOpp.Strategic_Info_Required__c = null;             //Added for 2-way communication
                                    renOpp.NextStep = null;
                                    renOpp.Opportunity_Notes__c = null;
                                    renOpp.Description = null;
                                    renOpp.Reason_for_early_renewal__c = null;
                                    renOpp.Reason_for_Request__c = null;
                                    renOpp.Alternatives_needed__c = null;
                                    renOpp.Open_service__c = null;
                                    renOpp.Sensitive_issues__c = null;
                                    renOpp.Delta_positioned_neutral_competitve__c = null;
                                    renOpp.Acquisitions_or_new_group_growing__c = null;
                                    renOpp.Competitive_considerations__c = null;
                                    renOpp.FFS_Number_of_Current_Primary_Enrollees__c = null;
                                    renOpp.FFS_Current_Carrier__c = 'Delta Dental';
                                    renOpp.FFSCompetitor__c = null;
                                    renOpp.FFS_Proposal_Value__c = null;
                                    renOpp.FFS_Rates_Awarded__c = null;
                                    renOpp.FFS_Awarded_To__c = null;
                                    renOpp.FFS_Reason_Lost_Sold_Decl_1__c = null;
                                    renOpp.FFS_Reason_1_Comment__c = null;
                                    renOpp.FFS_Reason_Lost_Sold_Decl_2__c = null;
                                    renOpp.FFS_Reason_2_Comment__c = null;
                                    renOpp.DHMO_Number_of_Current_Primary_Enrollees__c = null;
                                    renOpp.DHMO_Current_Carrier__c = 'Delta Dental';
                                    renOpp.DHMO_Competitor__c = null;
                                    renOpp.DHMO_Proposal_Value__c = null;
                                    renOpp.DHMO_Rates_Awarded__c = null;
                                    renOpp.DHMO_Awarded_To__c = null;
                                    renOpp.DHMO_Reason_Lost_Sold_Decl_1__c = null;
                                    renOpp.DHMO_Reason_1_Comment__c = null;
                                    renOpp.DHMO_Reason_Lost_Sold_Decl_2__c = null;
                                    renOpp.DHMO_Reason_2_Comment__c = null;
                                    renOpp.Renewal_Opportunity__c = null;
                                    renOpp.Sales_Notes_for_Implementation__c = null;//Added by Geetha for PC-14315
                                    String oppContractenddateStr = ''; 
                                    if(renOpp.Contract_End_Date__c!=null){
                                                                                  
                                        if(renOpp.Contract_End_Date__c.month()<10){
                                            oppContractenddateStr += '0';
                                        }
                                        oppContractenddateStr += String.valueof(renOpp.Contract_End_Date__c.month());
                                        
                                        if(renOpp.Contract_End_Date__c.day()<10){
                                            oppContractenddateStr += '/0';
                                        }else{
                                            oppContractenddateStr += '/';
                                        }
                                        oppContractenddateStr += String.valueof(renOpp.Contract_End_Date__c.day()); 
                                        
                                        oppContractenddateStr += '/'+ String.valueof(renOpp.Contract_End_Date__c.year());                    
                                    }
                                    
                                    //renOpp.Name = renOpp.Account.name + ' ' + renOpp.Contract_End_Date__c + ' ' + 'Renewal' ;
                                    
                                    if(renOpp.Account.name.length() > 100){
                                        renOpp.Name = renOpp.Account.name.subString(0,100) + ' ' + oppContractenddateStr + ' ' + 'Renewal' ;
                                    }else{
                                        renOpp.Name = renOpp.Account.name + ' ' + oppContractenddateStr + ' ' + 'Renewal' ;
                                    }
                                    
                                    renOpp.Reason_Won_Lost__c = NULL;
                                    renOpp.Enrollment_Date__c = NULL;
                                    renOpp.Description = NULL;  // Description - Requested Group Numbers
                                    renOpp.Opportunity_Notes__c = NULL;
                                    renOpp.ONYX_IncidentId__c  = NULL;
                                    P2EhContract.updatePrimaryEnrolled(renOpp,lcont);
                                    
                                    P2EhGlobalUtil.IsEligible = false;
                                    renOppToInsert.add(renOpp);
                                    dateOppMap.put(endDate, renOpp);//updated for 3.1
                                }
                                P2EhContract.updateShipAndBillAdd(lcont);
                                //system.debug('Line 705'+renOppToInsert);
                                P2EhGlobalUtil.IsEligible = true;
                                if(renOppToInsert.size()>0){
                                    try{
                                        insert renOppToInsert;
                                        system.debug(renOppToInsert+'Dev test:: checking for ids in renOpp(s) inserted ::: ' + dateOppMap);
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-104','Service Call Failed. Contact Administrator.'));
                                        system.debug('renOppToInsert insert failed :::' + renOppToInsert);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                    
                                }
                                if(grpContractMap.size()>0 || !grpContractMap.isEmpty() || grpContractMap!=null){
                                    for(Date endDate : reqDateGrpsMap.keyset()){//updated for 3.1
                                        for(String grpNbr : reqDateGrpsMap.get(endDate)){//updated for 3.1
                                            if(grpContractMap.get(grpNbr)!=null){
                                                if(dateOppMap.get(endDate)!=null){//updated for 3.1
                                                    grpContractMap.get(grpNbr).Renewal_Opportunity__c = dateOppMap.get(endDate).Id;//updated for 3.1
                                                }
                                                if(mapGrpGIHUpdated.get(grpNbr)!=null && dateOppMap.get(endDate)==null){
                                                    grpContractMap.get(grpNbr).Renewal_Opportunity__c = mapGrpGIHUpdated.get(grpNbr).Renew_Oppty_Hide__c;
                                                } 
                                            }
                                        }
                                    }
                                }
                                if(grpContractMap.size()>0){
                                    try{
                                        update grpContractMap.values();
                                        //update termContMap.values();
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-105','Service Call Failed. Contact Administrator.'));
                                        system.debug('grpContractMap.values() insert failed :::' + grpContractMap.values());
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                }
                                
                                //Creation of dummy Cases
                                List<Case> CaseToInsert = new List<Case>();
                                List<Credit__c> RenewalCreditList = new List<Credit__c>(); //Added for 2-way communication
                                //Id RecId = [Select Id, Name from RecordType where name = 'RFP'].Id;
                                //Id RecId1 = [Select Id, Name from RecordType where name = 'Implementation' AND SobjectType = 'Case'].Id;
                                for(Opportunity renOpp: renOppToInsert){
                                    Case rfpCase = new Case();
                                    rfpCase.Opportunity__c = renOpp.Id;
                                    rfpCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('RFP').getRecordTypeId();//RecId;
                                    rfpCase.AccountId = renOpp.AccountId;
                                    rfpCase.Related_Opportunity__c = renOpp.Id; // Added 01 Aug. Need to check the feasibility of removing Opportunity__c
                                    rfpCase.Type = 'RFP';
                                    rfpCase.Reason = 'Request For Proposal';
                                    rfpCase.Subject = 'RFP Case :::'; // Removed the last white space. It is not updating in db.
                                    CaseToInsert.add(rfpCase);   
                                    
                                    Case implCase = new Case();
                                    implCase.Opportunity__c = renOpp.Id;
                                    implCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Implementation').getRecordTypeId();//RecId1;
                                    implCase.Related_Opportunity__c = renOpp.Id;
                                    implCase.AccountId = renOpp.AccountId;
                                    implCase.Type = 'Implementation';
                                    implCase.Reason = 'Implementation';
                                    implCase.Subject = 'IMPL Case :::';
                                    CaseToInsert.add(implCase);  
                                    
                                    for(Credit__c rc:orgCreditList){  //Added for 2-way communication
                                        if(rc.Frequency__c=='Annual'){
                                            Credit__c newCredit = rc.clone();
                                            newCredit.Requested_Amount__c = rc.Granted_Amount__c;
                                            newCredit.Granted_Amount__c = null;
                                            newCredit.Opportunity__c = renOpp.Id;
                                            newCredit.Status__c = 'Draft';
                                            RenewalCreditList.add(newCredit);
                                        }
                                    }//Till Here 
                                }
                                
                                if(CaseToInsert.size()>0){
                                    try{
                                        insert CaseToInsert;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-107','Service Call Failed. Contact Administrator.'));
                                        system.debug('CaseToInsert insert failed :::' + CaseToInsert);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                }
                                
                                //Added for 2-way communication
                                if(RenewalCreditList.size()>0){
                                    try{
                                        insert RenewalCreditList;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-108','Service Call Failed. Contact Administrator.'));
                                        system.debug('RenewalCreditList insert failed :::' + RenewalCreditList);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                }//Till here
                                
                                //Creation of dummy Quote
                                List<Quote> QuoteToInsert = new List<Quote>();
                                for(Opportunity renOpp: renOppToInsert){
                                    Quote newQu = new Quote();
                                    newQu.Name = 'QC' + renOpp.Name;
                                    newQu.AutoQuote__c = true;
                                    newQu.OpportunityId = renOpp.Id;
                                    QuoteToInsert.add(newQu);
                                }
                                
                                if(QuoteToInsert.size()>0){
                                    try{
                                        insert QuoteToInsert;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-108','Service Call Failed. Contact Administrator.'));
                                        system.debug('QuoteToInsert insert failed :::' + QuoteToInsert);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                }
                                
                                //copy of contacts from New sale to Renewal
                                List<OpportunityContactRole__c> opptcontlist = [select id,Opportunity__c,Contact__c,Master_Opportunity__c,Opportunity__r.name,Contact__r.name,Internal__c,Contact__r.email,Contact__r.Phone,Role__c,Primary__c,ActiveStatus__c,Start_Date__c,End_Date__c,Task__c, Payment_Mode__c, Commission__c from OpportunityContactRole__c where Opportunity__c=:originopp.Id];
                                List<OpportunityContactRole__c> newopptlist = new List<OpportunityContactRole__c>(); 
                                for(Opportunity renOpp: renOppToInsert)
                                {
                                    for(OpportunityContactRole__c opptcont : opptcontlist)
                                    {
                                        OpportunityContactRole__c newopptcont = opptcont.clone();
                                        newopptcont.Opportunity__c = renopp.Id;
                                        newopptlist.add(newopptcont);
                                    }
                                }
                                if(newopptlist.size()>0){
                                    insert newopptlist;
                                } 
                                
                                //Creation of Opportunity Contacts                       
                                List<OpportunityContactRole__c> OCRlist = Database.Query(P2EhUtility.getQuery('OpportunityContactRole__c') + 'Where id = :oppId');                      
                                List<OpportunityContactRole__c> oppCntToInsert = new List<OpportunityContactRole__c>();
                                for(OpportunityContactRole__c OCR : OCRlist){
                                    for(Opportunity opp: renOppToInsert){
                                        OpportunityContactRole__c newOCR = OCR.clone();
                                        newOCR.Opportunity__r.Id= opp.Id; 
                                        oppCntToInsert.add(newOCR);   
                                    }     
                                }
                                
                                if(oppCntToInsert.size()>0){
                                    try{
                                        insert oppCntToInsert;
                                    }catch(Exception e){
                                        errorList.add(new P2EwService.ServiceError('SF002-106','Service Call Failed. Contact Administrator.'));
                                        system.debug('oppCntToInsert insert failed :::' + oppCntToInsert);
                                        system.debug(e.getMessage());
                                        Database.rollback(sp);
                                        return new P2EwService.SF001Response('Error', errorList);
                                    }
                                }
                            }
                        }
                    }
                }else{
                    errorList.add(new P2EwService.ServiceError('SF002-01','No Contract found in Request.'));
                }
            }else{
                errorList.add(new P2EwService.ServiceError('SF002-00','No Request Found'));
            }
            
            if(errorList.size()>0){
                return new P2EwService.SF001Response('Error', errorList);
            }else if(resp!=null){
                return resp;
            }
            return new P2EwService.SF001Response('OK');
        }catch(Exception e){
            P2EhGlobalUtil.ServiceErrorCde = 'SF002-000';
            P2EhGlobalUtil.ServiceErrorMsg = 'Service Failed. Contact Administrator.';
            throw new P2EException('P2EhIMPLRespService- sf002','', e);
        }
    }
    
    public Map<Id, List<Id>> FunctionRateSheetWithProdSegment(List<ProdSegment__c> lstProdSegment){
        Map<Id, List<Id>> mapProdIdRateSheetIds = new Map<Id, List<Id>>();
        Map<String, Id> mapRFPIdQuoteId = new Map<String, Id>();
        List<OpportunityLineItem> lstOLI = new List<OpportunityLineItem>();
        Set<Id> setProductIds = new Set<Id>();
        Set<String> setRFPIds = new Set<String>();
         for(ProdSegment__c ps: lstProdSegment){
            if(ps!=null){
                if(ps.Product__c != null) {  // code updated by rajesh PC-13631 & 13886
                    setProductIds.add(ps.Product__c);
                }
            }
        }
        lstOLI = [Select Id, RFP_Case_Id__c, Product2Id from OpportunityLineItem Where Product2Id IN: setProductIds and Parent_Impl_Case_Id__c=:reqcaseId];
        for(OpportunityLineItem oli: lstOLI){
            setRFPIds.add(oli.RFP_Case_Id__c);
        }
        for(Quote Q: [Select Id, RFP_Case_Id__c From Quote Where RFP_Case_Id__c IN: setRFPIds]){
            mapRFPIdQuoteId.put(Q.RFP_Case_Id__c, Q.Id);
        }
        for(RateSheet__c RS: [Select Id, Product2__c, Response_Quote__c, Request_Quote__c From RateSheet__c Where Response_Quote__c IN: mapRFPIdQuoteId.values() and Type__c='Activate']){//last condition added for PC-14145
            if(!mapProdIdRateSheetIds.containsKey(RS.Product2__c)){
                mapProdIdRateSheetIds.put(RS.Product2__c, new List<Id>());
            }
            mapProdIdRateSheetIds.get(RS.Product2__c).add(RS.Id);
        }
        return mapProdIdRateSheetIds;
    }
    
    
    /*@TestVisible private Contract frameContract(Contract cnt, String contStatus, Id accId, Id oppId, Id contractRTId, String oppName, P2EwService.QQContract reqCont, String oppType){//last parameter added for Pc-13726//commented for 3.1
        //Contract cont = new Contract();
        Contract cont;
        if(cnt!=null){
            cont = cnt;
        }else{
            cont = new Contract();
        }
        cont.Status = contStatus;
        cont.RecordTypeID = contractRTId;
        cont.AccountId = accId;
        //cont.Name = oppName + ' :: ' + reqCont.GroupNumber;
        if(reqCont.GroupName.length() > 80){
            cont.Name = reqCont.GroupName.subString(0, 80);
        }else{
            cont.Name = reqCont.GroupName;
        }
        if(reqCont.GroupNumber!=null){//geetha
            cont.Group_Number__c = reqCont.GroupNumber;
        }
        //cont.Name = reqCont.GroupName;
        cont.Opportunity__c = OppId;
         if(oppType=='Change'){//13726
          cont.Change_Opportunity__c=OppId;
        }//Till here for 13726
        cont.Company_UW_the_Group__c = reqCont.UnderwrittenBy;
        //cont.IsRenewalOpportunityShouldBeCreated__c = true;
        if(reqCont.NoOfEnrollees!=null){
            cont.Current_Delta_Primary_Enrollees__c = Integer.valueOf(reqCont.NoOfEnrollees);
        }
        if(reqCont.ContractTermFrom!=null && reqCont.ContractTermFrom!=''){
            cont.StartDate = date.valueOf(reqCont.ContractTermFrom.subString(0,4)+'-'+reqCont.ContractTermFrom.subString(4,6)+'-'+reqCont.ContractTermFrom.subString(6,8)+' 00:00:00');
        }
        //PC-13137 : Contract enddate        
        if(reqCont.ContractEndDate!=null && reqCont.ContractEndDate!=''){            
            cont.Contract_End_Date__c = date.valueOf(reqCont.ContractEndDate.subString(0,4)+'-'+reqCont.ContractEndDate.subString(4,6)+'-'+reqCont.ContractEndDate.subString(6,8)+' 00:00:00');        
        }
        //ContractTermTo assigned to Billing End Date
        if(reqCont.ContractTermTo!=null && reqCont.ContractTermTo!=''){
            cont.EndDate = date.valueOf(reqCont.ContractTermTo.subString(0,4)+'-'+reqCont.ContractTermTo.subString(4,6)+'-'+reqCont.ContractTermTo.subString(6,8)+' 00:00:00');
        }
        if(reqCont.RenewalDate!=null && reqCont.RenewalDate!=''){
            if(cont.EndDate!=null){
                cont.Contractual_Renewal_Date__c = cont.EndDate + 1;
            }
            else{
                cont.Contractual_Renewal_Date__c = date.valueOf(reqCont.RenewalDate.subString(0,4)+'-'+reqCont.RenewalDate.subString(4,6)+'-'+reqCont.RenewalDate.subString(6,8)+' 00:00:00');
            }
            
        }
        if(reqCont.ContractTerm!=null){
            cont.ContractTerm__c = Integer.valueOf(reqCont.ContractTerm);
        }
        if(reqCont.RenewalClause!=null){
            cont.Renewal_clause__c = Integer.valueOf(reqCont.RenewalClause);
            cont.Proposed_Initiation_Days__c = Integer.valueOf(reqCont.RenewalClause);
        }
        if(reqCont.GroupTermDate!=''){//13770
            cont.Group_Term_Date__c = date.valueOf(reqCont.GroupTermDate.subString(0,4)+'-'+reqCont.GroupTermDate.subString(4,6)+'-'+reqCont.GroupTermDate.subString(6,8)+' 00:00:00');
        }//Till here for 13770
        return cont;
    }*/ //commented for 3.1
    
    /**
     * @Description: As part of GAMMA new group changes, Murali added this Method to find the existing group and link the opportunity.     
     * @Param  : Group Number, OpportunityID and Opportunity Type
     * @Return : Returns the existing group with the same groupnumber
     **/
    /*@TestVisible private Contract findExistingGroup(String groupNumber,Id oppId, String oppType){ 
                                                       
            String contractQuery = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Contract').getDescribe().fields.getMap().keySet()), ',') + ',Opportunity__r.Type,Renewal_clause__c,Opportunity__r.Id,Change_Opportunity__r.Id FROM Contract';
            contractQuery = contractQuery+' WHERE Group_Number__c=\''+ groupNumber +'\' AND (Status =\'Draft\' OR Status =\'Activated\') ORDER BY Status DESC NULLS LAST LIMIT 1';
            List<Contract> existingGroups = GCQueryHelper.getQueryResult(contractQuery);
            system.debug('existingGroups ###'+existingGroups);
            
            if(existingGroups.size()>0){
                 Contract cont = existingGroups.get(0);
                 cont.Opportunity__c = OppId;
                 if(oppType=='Change'){
                  cont.Change_Opportunity__c=OppId;
                }
                return cont;
            }
            return null;
     }*/
     
    
    @TestVisible private Contact frameContact(Id accId, P2EwPegaService.QQContacts con){
        Contact cont = new Contact();
        cont.AccountId = accId;
        cont.FirstName = con.FirstName;
        cont.LastName = con.LastName;
        cont.Title = con.TitleName;
        cont.Phone = con.PhoneNumber;
        cont.Email = con.Email;
        cont.Fax = con.Fax;
        Map<String, String> mapStateStateCode = new Map<String, String>();
        for(US_State__c USSC: [Select Id, Name, State__c, State_Code__c From US_State__c]){
            mapStateStateCode.put(USSC.State_Code__c, USSC.State__c);
        }  
       
        if(con.AddressesList!=null && con.AddressesList.size()>0){
            for(P2EwPegaService.QQAddressesList addr : con.AddressesList){
                if(addr.Type.equals('Mailing')){
                    cont.MailingCity = addr.City;
                    if(addr.Country != Null && addr.Country != ''){
                        cont.MailingCountry = addr.Country;
                    }else{
                        cont.MailingCountry = 'United States';
                    }
                    
                    cont.MailingState = mapStateStateCode.get(addr.State);
                    cont.MailingPostalCode = addr.Zip;
                    if(addr.StreetAddress == null){
                        addr.StreetAddress = '';
                    }
                    if(addr.AddressLine1 == null){
                        addr.AddressLine1 = '';
                    }
                    if(addr.AddressLine2 == null){
                        addr.AddressLine2 = '';
                    }
                    cont.MailingStreet = addr.StreetAddress + addr.AddressLine1 + addr.AddressLine2;
                }
                if(addr.Type.equals('Other')){
                    cont.OtherCity = addr.City;
                    if(addr.Country != Null && addr.Country != ''){
                        cont.OtherCountry = addr.Country;
                    }else{
                        cont.OtherCountry = 'United States';
                    }
                    cont.OtherState = mapStateStateCode.get(addr.State);                    
                    cont.OtherPostalCode = addr.Zip;
                    if(addr.StreetAddress == null){
                        addr.StreetAddress = '';
                    }
                    if(addr.AddressLine1 == null){
                        addr.AddressLine1 = '';
                    }
                    if(addr.AddressLine2 == null){
                        addr.AddressLine2 = '';
                    }
                    cont.OtherStreet = addr.StreetAddress + addr.AddressLine1 + addr.AddressLine2;
                }
            }
        }
        return cont;
    }
    
    
    @TestVisible private Set<Date> strToDate(Set<String> dateStrLst){
        Set<Date> dateRtn = new Set<Date>();
        for(String dateStr : dateStrLst){
            dateRtn.add(Date.valueOf(dateStr.subString(0,4)+'-'+dateStr.subString(4,6)+'-'+dateStr.subString(6,8)+' 00:00:00'));
        }
        return dateRtn;
    }
}