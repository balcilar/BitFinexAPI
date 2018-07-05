clear all
clc

%% DATA PULL
key   ='TYPE YOUR KEY';
secret='TYPE YOUR SECRET KEY';

url_ext='/v1/history';             


method='';  % bitcoin litecoin darkcoin wire  TETHERUSO          leave blank for Ledger History (Method is just for Movement History)
currency={'USD','BCH','BFX','BTC','BTG','DSH','EOS','ETH','IOT','NEC','OMG','QSH','XMR','XRP','ZEC'};

C=length(currency);
endtime=now;                    % (can use 'now' or input datenum format)
starttime=datenum(2015,1,1);
limit=5000;                     % number of lines
wallet={'deposit';'exchange';'trading'}; % trading  exchange deposit

url='https://api.bitfinex.com';
url=[url url_ext];
        
        
for c=1:C
    for w=1:3
        
        nline=0;
        
        
        % output file definition: you can give *.csv file name or it can defined automatically
        filename=[currency{c} '_' wallet{w} '.csv'];
        
        valueText='ERR_RATE_LIMIT'; 
        
        % MAIN BLOCK
        
        since= [ num2str(floor((starttime-datenum('1970', 'yyyy'))*86400)) '.0'];
        until= [ num2str(floor((endtime  -datenum('1970', 'yyyy'))*86400)) '.0'];
        
        
        VALUE=[];
        
        while  (str2num(until)>str2num(since) & nline<limit & ~strcmp(valueText, 'empty'))
            
                        
            nonce =  num2str(floor((now      -datenum('1970', 'yyyy'))*8640000000));
            
                        
            payload_json=['{"nonce": "' nonce '", "request": "' url_ext ];
            if length(currency{c})>0; payload_json=[payload_json '", "currency": "' currency{c}]; end
            if length(until)>0;       payload_json=[payload_json '", "until": "'          until]; end
            if length(since)>0;       payload_json=[payload_json '", "since": "'          since]; end
            if length(method)>0;      payload_json=[payload_json '", "method": "'        method]; end
            if length(wallet{w})>0;   payload_json=[payload_json '", "wallet": "'     wallet{w}]; end
            if length(limit)>0;       payload_json=[payload_json '", "limit": ' num2str(limit) '}'];
            else                      payload_json=[payload_json  '"}'];                          end
            payload_uint8 = uint8(payload_json);
            payload       = char(org.apache.commons.codec.binary.Base64.encodeBase64(payload_uint8))';
            Signature       = char(crypto(payload, secret, 'HmacSHA384'));
            
            header(1)=struct('name','X-BFX-APIKEY'   ,'value',key);
            header(2)=struct('name','X-BFX-PAYLOAD'  ,'value',payload);
            header(3)=struct('name','X-BFX-SIGNATURE','value',Signature);
            
            [response,status] = urlread2(url,'POST','',header);
            
            value = jsondecode(response);
            
            if  isempty(value); valueText= 'empty';                                    end
            if ~isempty(value); valueText= struct2cell(value); valueText=valueText{:};end
            
            if strcmp(valueText,'ERR_RATE_LIMIT')
                disp('Rate Limited = waiting 60 seconds');
                pause(60);
            end
            
            if ~isempty(value) && ~strcmp(valueText,'ERR_RATE_LIMIT')
                
                until=[num2str(str2num(value(end).timestamp)-1) '.0'];
                nline=nline+length(value); 
                
            end               
                
            
            for i=1:length(value)
                if isfield(value, 'timestamp');         value(i).timestamp        =datestr(str2num(value(i).timestamp)        /86400+datenum('1970', 'yyyy')); end
                if isfield(value, 'timestamp_created'); value(i).timestamp_created=datestr(str2num(value(i).timestamp_created)/86400+datenum('1970', 'yyyy')); end
            end
            
            if length(value)>0 && ~strcmp(valueText,'ERR_RATE_LIMIT')
                VALUE=[VALUE;value];
            end
            
            
            
        end
        
        if length(VALUE)>0
            table=struct2table(VALUE);
            pause(2);
            writetable(table, filename);            
        end
        
    end
end
