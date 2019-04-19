/**
* @author Hitendar
* @date 04Nov2015
    * @description : Helper class for contract
*  @Changes 
*             {Issac Pal} {21/11/2018} –{Added new method(enableDisableApplyChangesBtn) to show button based on the Record Type}
*/

public class P2EhContract{
    public static boolean updateCntrt=true; // PC-15278 to avoid recursion
    private static boolean CheckStage = true;
    //Method to update the FFS and DHMO primary enrolled from the contract to Renewal Opportunity
    public static void updatePrimaryEnrolled(Opportunity opp, List<Contract> conts){
        opp.FFS_Number_of_Current_Primary_Enrollees__c = 0;
        opp.DHMO_Number_of_Current_Primary_Enrollees__c = 0;
        for(Contract c : conts){
            if(c.EndDate == opp.Contract_End_Date__c){
                if(c.Current_Delta_Primary_Enrollees__c != null && c.status == 'Activated'){
                    if(c.Product_Name__c == 'DHMO'){
                        opp.DHMO_Number_of_Current_Primary_Enrollees__c += c.Current_Delta_Primary_Enrollees__c;
                    }
                    else{
                        opp.FFS_Number_of_Current_Primary_Enrollees__c += c.Current_Delta_Primary_Enrollees__c;
                    }
                }
                opp.Old_Opportunity_Name__c = c.Opportunity__c;
            }
        }
    }
    
    
    
    public static void updateShipAndBillAdd(List<contract> conts){
        set<Id> lstaccId = new set<Id>();
        List<Account> accList = new List<Account>();
        for(contract c : conts){
            lstaccId.add(c.AccountId);
        }
        if(lstaccId.size()>0){
            acclist = Database.Query(P2EhUtility.getQuery('Account') + 'Where id in: lstaccId');
            for(contract c : conts){
                for(Account acct :acclist){
                    if(acct.Id == c.AccountId){
                        /*if(c.Acc_Manager_Email__c != null){
c.Account_Manager_Email__c=c.Acc_Manager_Email__c;  
}*/
                        c.BillingCity=acct.BillingCity;  
                        c.BillingCountry=acct.BillingCountry;
                        c.BillingCountryCode=acct.BillingCountryCode;
                        c.BillingPostalCode=acct.BillingPostalCode;
                        c.BillingState=acct.BillingState;
                        c.BillingStateCode=acct.BillingStateCode;
                        c.BillingStreet=acct.BillingStreet;
                        c.ShippingCity=acct.ShippingCity;
                        c.ShippingCountry=acct.ShippingCountry;
                        c.ShippingCountryCode=acct.ShippingCountryCode;
                        c.ShippingPostalCode=acct.ShippingPostalCode;
                        c.ShippingState=acct.ShippingState;
                        c.ShippingStateCode=acct.ShippingStateCode;
                        c.ShippingStreet=acct.ShippingStreet;
                        if(acct.Current_Delta_Primary_Enrollees__c==null){
                            acct.Current_Delta_Primary_Enrollees__c = 0;
                        }
                        if(c.Current_Delta_Primary_Enrollees__c != null && c.status == 'Activated'){
                            if(acct.Current_Delta_Primary_Enrollees__c == null){
                                acct.Current_Delta_Primary_Enrollees__c = 0;
                            }
                            acct.Current_Delta_Primary_Enrollees__c += c.Current_Delta_Primary_Enrollees__c;
                            
                        }
                    }
                }
            }
            if(accList.size()>0){
                update acclist;
            }
        }
        
    }
    
    
    
    public static void deleteContract(List<contract> cntrt){
        set<Id> oppId = new set<Id>();
        set<Id> accId= new set<Id>();
        for(Contract c: cntrt){
            oppId.add(c.Renewal_Opportunity__c);
            accId.add(c.AccountId);
        }       
        System.debug('DELETE CONTRACT **' + oppId);
        if(oppId.size()>0){
            list<Opportunity> ProEnr = [select Id,DHMO_Number_of_Current_Primary_Enrollees__c,FFS_Number_of_Current_Primary_Enrollees__c,Proposed_No_of_Enrollees__c, Eligible_Primary_Enrollees__c, Number_of_Renewal_Lives__c from Opportunity where id IN : oppId]; 

            for(Contract c: cntrt){
                for(Opportunity opp:ProEnr ){  
                    if(opp.Id == c.Renewal_Opportunity__c){
                        if(c.Current_Delta_Primary_Enrollees__c!=null){
                        if(c.Product_Name__c == 'DHMO' && opp.DHMO_Number_of_Current_Primary_Enrollees__c!=null){
                            opp.DHMO_Number_of_Current_Primary_Enrollees__c -= c.Current_Delta_Primary_Enrollees__c;
                        }
                        else{
                            if(opp.FFS_Number_of_Current_Primary_Enrollees__c!=null){
                                opp.FFS_Number_of_Current_Primary_Enrollees__c -= c.Current_Delta_Primary_Enrollees__c;
                            }  
                        }
                        }
                        
                    }
                }
                
            }
            if(ProEnr.size() > 0){
                system.debug(' proenr ' + ProEnr);
                update ProEnr;
            }
        }
        if(accId.size()>0){
            List<account> accList=[select id,Current_Delta_Primary_Enrollees__c,name from account where id In:accId];
            for(Contract c: cntrt){
                for(account acc:accList){
                    if(c.accountId==acc.Id && acc.Current_Delta_Primary_Enrollees__c!=null){
                        system.debug(acc);
                        system.debug(c);
                        if(c.Current_Delta_Primary_Enrollees__c != null){
                            acc.Current_Delta_Primary_Enrollees__c -= c.Current_Delta_Primary_Enrollees__c;
                        } 
                        
                    } 
                }
            }
            if(acclist.size()>0){
                update acclist;
            } 
        }
    }
    
    /*public static void unlockApprovedGroupInfo(String rId) {//3.1 Start
        boolean isSuccess;
        Approval.UnlockResult unlockedResult = Approval.unlock(rId);
        // Iterate through each returned result
        if (unlockedResult.isSuccess()) {
            isSuccess = true;
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully unlocked contract with ID: ' + unlockedResult.getId());
        }
        else {
            // Operation failed, so get all errors               
            for(Database.Error err : unlockedResult.getErrors()) {
                System.debug('Contract fields that affected this error: ' + err.getMessage());
            }
        }
    }*///3.1 End
    
    public static void UpdateProductType(List<Contract> newlist,Map<ID, Contract> oldTriggerMap){
        set<Id> oppId=new set<Id>();
        set<Id> cntrtId=new set<Id>();//13770
        set<Id> cntrtPrdSet=new set<Id>();//13770
        set<Id> allRenOppIdSet = new set<Id>(); //T&T
        //List<contract> cntrtToUpdate=new List<Contract>();//added for 3.1
        System.debug(newlist);
        System.debug(oldTriggerMap);
        system.debug('allRenOppIdSet'+allRenOppIdSet);
        for(Contract cont: newlist){
            System.debug(cont.status);
            if(cont.status=='Terminated'){// && oldTriggerMap.get(cont.Id).status!='Terminated'){//13770 start
                cntrtId.add(cont.Id);
                system.debug('Renewal Oppty'+oldTriggerMap.get(cont.Id).Renewal_Opportunity__c);
                if(oldTriggerMap.get(cont.Id).Renewal_Opportunity__c!=null){
                    system.debug('oldTriggerMap.get(cont.Id).Renewal_Opportunity__c'+oldTriggerMap.get(cont.Id).Renewal_Opportunity__c);
                    allRenOppIdSet.add(oldTriggerMap.get(cont.Id).Renewal_Opportunity__c);
                    system.debug('allRenOppIdSet'+allRenOppIdSet);
                }
                /*
if(cont.Renewal_Opportunity__c != null) {
allRenOppIdSet.add(cont.Renewal_Opportunity__c);
}
*/ 
                /*try{//3.1 start
                    unlockApprovedGroupInfo(cont.Id);
                    cont.Renewal_Opportunity__c =null;
                    cntrtToUpdate.add(cont);
                }catch(Exception e){
                    system.debug('exception:'+e);
                }*///3.1 End
                
            } 
            Contract old = oldTriggerMap.get(cont.Id);
            if(old.Product_Name__c != cont.Product_Name__c){
                oppId.add(cont.Opportunity__c);
            }           
            system.debug('Line 139' + oppId);
        }
        /*if(cntrtToUpdate.size()>0){//3.1 Start
            update cntrtToUpdate;
        }*///3.1 End
        if(cntrtId.size()>0){
            set<Id> renOppIdSet = new set<Id>(); //T&T
            set<Id> reqOppIdSet = new set<Id>(); //T&T
            List<ContractProduct__c> cntrtPrdLst = [select id,Contract__c,Product__c from ContractProduct__c where Contract__c in:cntrtId];
            if(cntrtPrdLst.size()>0){
                for(ContractProduct__c cntrtPrd:cntrtPrdLst){
                    cntrtPrdSet.add(cntrtPrd.Product__c);
                }
                List<ProdBenefit__c> prdBenLst = [select id,Product__c from ProdBenefit__c where Product__c in:cntrtPrdSet];
                if(prdBenLst.size()>0){
                    delete prdBenLst;
                }
                delete cntrtPrdLst;
            }
            List<Segmentation__c> segLstToUpdate = [select id,status__c from segmentation__c where Contract__c in:cntrtId];
            if(segLstToUpdate!=null){
                for(Segmentation__c seg:segLstToUpdate){
                    seg.status__c='Terminated';
                }
            }
            update segLstToUpdate;
            //Term & Transfer
            //system.debug('P2EhIMPLRespService.isSf002'+P2EhIMPLRespService.isSf002);
            //if(P2EhIMPLRespService.isSf002==false)
            system.debug('allRenOppIdSet ---> '+allRenOppIdSet);
            //system.debug('allRenOppIdSet SIZE ---> '+allRenOppIdSet.size());
            //system.debug('allRenOppIdSet ISEMPTY ---> '+allRenOppIdSet.isEmpty());
            if(allRenOppIdSet.size()>0){
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
                    set<Id> noActiveContractAccIdSet = new set<Id>();
                    List<Account> acctToUpdate = new List<Account>();
                    List<Opportunity> oppUdateLst = [select id,AccountId,stagename,Workflow_Stage__c from opportunity where id in:reqOppIdSet];
                    for(Opportunity upOpp:oppUdateLst){
                        upOpp.stagename = Label.Sales_Stages_Won;
                        upOpp.Workflow_Stage__c = Label.Sales_Stages_Closed_After_MTV_Implementations;
                        allaccIdSet.add(upOpp.AccountId);       
                    }
                    update oppUdateLst;
                    List<Contract> allcntrtLst1 = [Select id, Group_Term_Date__c,status,Renewal_Opportunity__c,AccountId from Contract where AccountId in:allaccIdSet and status='Activated'];
                    for(Contract cnt:allcntrtLst1){                                        
                        acctIdSet.add(cnt.AccountId);
                    }
                    
                    for(Id accId:allaccIdSet){
                        if(!acctIdSet.contains(accId)){
                            noActiveContractAccIdSet.add(accId);
                        }
                    }
                    
                    RecordType recordtype=[select Id from RecordType where Name = 'Prospect' and SobjectType = 'Account'];
                    
                    acctToUpdate = [select id,RecordTypeId from Account where id in:noActiveContractAccIdSet];
                    for(Account upAcct:acctToUpdate){
                        upAcct.RecordTypeId = recordtype.Id;  
                    }
                    if(acctToUpdate!=null){
                        update acctToUpdate;
                    }
                }
            }            
            
        }//13770 End       
        list<Opportunity> opp=new List<Opportunity>();
        opp = [select id,Name,Program_Type__c from Opportunity where id IN:oppId];
        List<Contract> conList = new List<Contract>();
        
        Map<Id,List<Contract>> oppMap = new Map<Id,List<Contract>>();
        conList = [select id,Name,opportunity__c,Product_Name__c from contract where opportunity__c in:oppId];
        for(Contract con : conList){
            if(oppMap.get(con.Opportunity__c) == null){
                oppMap.put(con.Opportunity__c,new List<Contract>()); 
            }  
            oppMap.get(con.Opportunity__c).add(con);  
        }
        
        set<string> sePt;
        string tempstr; 
        List<opportunity> opptyToUpdate = new List<opportunity>();
        for(Opportunity oppt:[Select id,Name,Program_Type__c from Opportunity where Id in:oppMap.keyset()]){
            sePt = new set<string>();
            for(Contract con:oppMap.get(oppt.id)){
                sePt.add(con.Product_Name__c);
            }
            system.debug('Line 161' + sePt);
            tempStr = '';
            for(string str: sePt){
                if(str == 'Fee For Service'){
                    str = 'FFS';
                }
                if(str == 'DHMO'){
                    str = 'DHMO';
                }
                if(str == 'Flexible Dual Choice (FFS)'){
                    str = 'FDS';
                }
                if(str == 'Dentegra (FFS)'){
                    str = 'Dentegra (FFS)';
                }
                tempstr += str+',';
            }
            tempstr = tempstr.removeEnd(',');
            oppt.Program_Type__c = tempstr;
            opptyToUpdate.add(oppt);
        }
        if(opptyToUpdate.size()>0){
            update opptyToUpdate;
        }
        //Change account type from customer to Prospect. Done by Nathiya 
        List<Account> accListUpdate = new List<Account>();    
        set<Id> accId = new set<Id>();
        for(Contract cont:newlist){
            accId.add(cont.AccountId);
        }
        
        list<Account> acc=new List<Account>();
        acc = [select id,Name,Account_Record_Type__c from Account where id IN:accId];
        List<Contract> contList = new List<Contract>();
        contList=[Select id,accountid, status from contract where contract.accountid=:accId];
        system.debug('!!!!contList'+contList);     
        Map<Id,List<Contract>> accMap = new Map<Id,List<Contract>>();
        
        
        for(Contract con: contList){
            if(accMap.get(con.AccountId)== null){
                accMap.put(con.AccountId, new List<Contract>());
            }
            accMap.get(con.AccountId).add(con);    
        }
        
        for(Account acct:acc){      
            Boolean isAllTerminated = true;            
            for(Contract cntrt:accMap.get(acct.Id)){   
                system.debug('cntrt****'+cntrt.status);                   
                if(cntrt.status =='Activated' || cntrt.status =='Draft'){
                    isAllTerminated = false;
                    break;
                    //   acct.RecordTypeID = P2EhUtility.getRecordTypeId('Account', 'Prospect');                     
                }
            }
            if(isAllTerminated){
                acct.Prior_Delta_Group__c = true;
                accListUpdate.add(acct);  
            }
        }
        if(accListUpdate.size()>0){
            update accListUpdate;
        }
        //updateCntrt=false; // condition added PC-15278//commented for 3.1
        
    }
}