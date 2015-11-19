%%
files = dir('~/proj/cohcon_mturk/mat/*2015-09-03*.mat');

for fi = 1:length(files)
    load(fullfile('~/proj/cohcon_mturk/mat',files(fi).name));
    
    %% TODO:
%     long = ccmt_2long(); 
%     catlong = ccmt_catLong();
    
    if iscell(jglData.correct)
        jglData.corrected = [];
        for i = 1:length(jglData.correct)
            if strcmp(jglData.correct{i},'null')
                jglData.corrected(i) = 0;
            else
                jglData.corrected(i) = jglData.correct{i};
            end
        end
        jglData.correct = jglData.corrected;
    end
    mean(jglData.correct)
    %%
%     e = getTaskParameters(myscreen,task);
    
    if isfield(jglData,'lCon')
        figure
        
        % split by task
        crit = jglData.crit;
        prac = jglData.prac;
        noresp = jglData.responses==0;
        task = jglData.task(logical(~crit.*~prac.*~noresp));
        resp = jglData.responses(logical(~crit.*~prac.*~noresp));
        resp = resp -1; % 0 left, 1 right
        corr = jglData.correct(logical(~crit.*~prac.*~noresp));
        
        dCon = jglData.rCon(logical(~crit.*~prac))-jglData.lCon(logical(~crit.*~prac));
        dCoh = jglData.rCoh(logical(~crit.*~prac))-jglData.lCoh(logical(~crit.*~prac));
       
        tasks = {'coherence','contrast'};
        cond = {'coherence','contrast'};
        colors = {'*b','*r'};
        data = struct; stats = {};
        for ti = 1:length(tasks)
            subplot(2,1,ti), hold on
            title(sprintf('Effect of Stimulus Features on Right Choice Probability for Task: %s',tasks{ti}));
            data.(tasks{ti}).dcon = dCon(task==ti);
            data.(tasks{ti}).dcoh = dCoh(task==ti);
            data.(tasks{ti}).resp = resp(task==ti);
            data.(tasks{ti}).corr = corr(task==ti);
            
            % now fit a sigmoid, we'll just do the basic thing first and
            % average at each response level
            ucon = unique(dCon);
            ucoh = unique(dCoh);
            bcon = [-inf, ucon(1:end-1) + diff(ucon/2), inf];
            bcoh = [-inf, ucoh(1:end-1) + diff(ucoh/2), inf];
            rchoice = binData(resp(task==ti),dCon(task==ti),bcon);
            rmean = cellfun(@mean,rchoice);
            plot(ucon,rmean,colors{2});
            rchoice = binData(resp(task==ti),dCoh(task==ti),bcoh);
            rmean = cellfun(@mean,rchoice);
            plot(ucoh,rmean,colors{1});
            
            X = [dCoh(task==ti)',dCon(task==ti)'];
            Y = resp(task==ti)';
            
            [B,dev,stats{ti}] = glmfit(X,Y,'binomial','link','logit');
            
            conrange = ucon(1):.01:ucon(end);
            cohrange = ucoh(1):.01:ucoh(end);
            y = glmval(B,[zeros(length(conrange),1),conrange'],'logit');
            plot(conrange,y,'-r');
            y = glmval(B,[cohrange',zeros(length(cohrange),1)],'logit');
            plot(cohrange,y,'-b')
            xlabel('Stim Intensity');
            ylabel('% Right Choices');
            
            legend({'Contrast','Coherence'});
            
        end
        
    end
    
    %%
end