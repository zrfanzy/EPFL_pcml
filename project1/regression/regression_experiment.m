load('Shanghai_regression.mat');
labely = zeros(length(y_train), 1);

for i = 1 : length(y_train)
    if y_train(i) < 4000
        labely(i) = 1;
    elseif y_train(i) > 7600
        labely(i) = 3;
    else
        labely(i) = 2;
    end
end


X = normalizeFeature(X_train);

binary_ft = [18,19,20,35,47];
categori_ft = [13,16,17,22,36,49,52,54];
non_norm = [13,16,17,22,36,18,19,20,35,47,49,52,54];

% find outlier with easy leastSquares & remove
figure;
for label = 1 : 3
    ind = find(labely == label);
    N = length(y_train(ind));
    tX = [ones(N, 1) X(ind)];
    beta = leastSquares(y_train(ind), tX);
    
    tY = tX * beta;
    % histogram errors by leastsquares
    subplot(3, 1, label);
    hist(abs(tY - y_train(ind)), 100);
    
    % remove outliers
    for j = length(ind):-1:1
        if abs(tY(j) - y_train(ind(j))) > 2000
            X(ind(j),:)=[];
            y_train(ind(j),:)=[];
            labely(ind(j)) = [];
        end
    end
end

% train for each label
for label = 1 : 3 
    figure;
    clear idxCV;
    clear mseTr_degree;
    clear mseTe_degree;
    
    ind = find(labely == label);
    thisY = y_train(ind);
    N = length(thisY)

    seeds = 1:1;
    for s = 1 : length(seeds)
        setSeed(seeds(s));

        % degrees
        for degree  = 2:4
            X_ind = X(ind,:);
            X_expand = zeros(size(y_train(ind),1),1);
            for i=1:71
                if(~isempty(find(categori_ft == i)))
%            append_cols = normalizeFeature(X_train(:,i));
                    append_cols = dummy_encoding(X_ind(:,i)');
                    X_expand = [X_expand append_cols];
                elseif(~isempty(find(binary_ft == i))) 
                    append_cols = X_ind(:,i);
                    X_expand = [X_expand append_cols];
                elseif(i==57 || i ==65 ||i ==21||i==27||i==69||i==34||i==51||i==5||i==45)
                    continue;
                else 
                    append_cols = X_ind(:,i);
                    append_cols = mypoly(append_cols,degree);
                    append_cols = normalizeFeature(append_cols);
                    X_expand = [X_expand append_cols];
          
                end
            end
            tX = X_expand(:,2:size(X_expand,2));%ones(N, 1) mypoly(X(ind,:), degree)];
            %tX = [ones(N,1) X(ind,:)];

            % K fold
            K = 5;
            Nk = floor(N/K);
            idx = randperm(Nk * K);

            for k = 1:K
                idxCV(k,:) = idx(1+(k-1)*Nk:k*Nk);
            end

            lambda = logspace(-2,0,20);
            
            lambda = [0,lambda];
            %lambda = [0];
            
            for i = 1:length(lambda)
                % K-fold cross validation for each lambda
                for k = 1:K
                % get k'th subgroup in test, others in train
                    idxTe = idxCV(k,:);
                    idxTr = idxCV([1:k-1 k+1:end],:);
                    idxTr = idxTr(:);

                    yTe_cv = thisY(idxTe);
                    XTe_cv = tX(idxTe,:);

                    yTr_cv = thisY(idxTr);
                    XTr_cv = tX(idxTr,:);

                    tXTr_cv = [XTr_cv];
                    tXTe_cv = [XTe_cv]; 

                    % ridge regression    
                    beta = ridgeRegression(yTr_cv,tXTr_cv,lambda(i));

                    mseTrSub(k) = computeCost(yTr_cv, tXTr_cv, beta); 
                    mseTeSub(k) = computeCost(yTe_cv, tXTe_cv, beta);
                end
                % compute the mean error for k cross validation of the same lambda
                fprintf('dg %d mean%dfold for lambda %.2f\n',degree,k,lambda(i));

                rmseTr_lamb(label, i) = mean(mseTrSub);
                rmseTe_lamb(label, i) = mean(mseTeSub);
                fprintf('tr %.4f te %.4f\n ',rmseTr_lamb(label, i),rmseTe_lamb(label, i));
            %         box(:,i) = mseTeSub;
            end % end of runing for different lambda

            [numb(label),index_best_lambda(label)] = min(rmseTe_lamb(label));
            % by cv find lambda, use the lambda to train and test, get the performance
            % of the degree(diff model complexity)
            prop = 0.7;
            [XTr, yTr, XTe, yTe] = split(y_train(ind), tX, prop);
            tXTr = XTr;
            tXTe = XTe;
            beta = ridgeRegression(yTr,tXTr,lambda(index_best_lambda(label)));
            %beta = leastSquares(yTr, tXTr);
            max(beta)
            if label == 1
                ridgebeta1 = beta;
                ridgelambda1 = lambda(index_best_lambda(label));
            elseif label == 2
                ridgebeta2 = beta;
                ridgelambda2 = lambda(index_best_lambda(label));
            else
                ridgebeta3 = beta;
                ridgelambda3 = lambda(index_best_lambda(label));
            end
            mseTr_degree(s,degree) = computeCost(yTr, tXTr, beta);
            mseTe_degree(s,degree) = computeCost(yTe, tXTe, beta);

            %fprintf('\ndegree %d ; lambda %f;  test: %.4f; train:%.4f \n',...
            %degree, lambda(index_best_lambda),...
            %mseTe_degree(s,degree),mseTr_degree(s,degree));
            
            fprintf('\ndegree %d ; test: %.4f; train:%.4f \n',...
            degree,...
            mseTe_degree(s,degree),mseTr_degree(s,degree));
        end

    end% for different seed, repeated again

    for s = 1:length(seeds)
        %plot(2:4,mseTr_degree(s,:),'b');hold on;
        %plot(2:4,mseTe_degree(s,:),'r');hold on;grid on;
    end
    
end
