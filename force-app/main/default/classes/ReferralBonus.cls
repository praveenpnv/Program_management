Public class ReferralBonus
{
    public static void setupreferralBonus(set<id> userId)
    {
        List<Torc_User__c>lsttu=[Select ID, Referrer__c, Exclude_Referral_Bonus__c, Referrer__r.Exclude_Referrer_Bonus__c,
                            (Select Payment_Week__c, Referred_By__c, referral_Payment_Created__c, referrer_Payment_Created__c 
                                from Referral_Bonus__r),
                            (Select First_Working_Day__c,Last_Working_Day__c from placements__r 
                                Where First_Working_Day__c!=NULL AND Last_Working_Day__c!=NULL
                                Order By First_Working_Day__c)
                         FROM Torc_User__c Where ID in :userId];
        
        list<Referral_Bonus__c>lstrb=new list<Referral_Bonus__c>();
        list<Referral_Bonus__c>lstrbDel=new list<Referral_Bonus__c>();
        for(torc_User__c tu:lsttu)
        {      
            List<Placement__c> lstP = tu.placements__r;
            if(tu.Referral_Bonus__r.size()>0 && (tu.Referral_Bonus__r[0].referral_Payment_Created__c==true || tu.Referral_Bonus__r[0].referrer_Payment_Created__c==true))
                continue;
             date fd=null;
             Date ld=null;
             for(Placement__c p:lstP)
             {
                 fd=fd==null?p.First_Working_Day__c:(fd>p.First_Working_Day__c?p.First_Working_Day__c:fd);
                 ld=ld==null?p.last_Working_Day__c:(ld<p.last_Working_Day__c?p.last_Working_Day__c:ld);
             }
             if(fd!=NULL && ld!=NULL && tu.Referrer__c!=NULL 
                                 && tu.Referrer__r.Exclude_Referrer_Bonus__c !=TRUE
                                 && tu.Exclude_Referral_Bonus__c !=TRUE
               )
             {
                Referral_Bonus__c rb;
                if(tu.Referral_Bonus__r.size()>0)
                    rb = tu.Referral_Bonus__r[0];
                else
                    rb = new Referral_Bonus__c( Referred_to__c = tu.id);
                rb.Referred_By__c = tu.Referrer__c;    
                rb.Payment_Week__c = fd.addmonths(1);
                lstrb.add(rb);
             }
             else
            {
                lstrbDel.addAll(tu.Referral_Bonus__r);
                continue;
            }
        }
        if(lstrbDel.size()>0)
            delete lstrbDel;
        if(lstrb.size()>0)    
            upsert lstrb;    
    }
}