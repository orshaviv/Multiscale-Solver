classdef ArteryVessel < Artery
    properties
        dt = 1; %Seconds
        TotalTime = 15; %Minutes
    end
    methods
        %Radius and etc.
        function Ri = Ri(obj)
            Ri = obj.Ro-obj.H0; % inner radii
        end
        function hadv = hadv(obj)
            hadv = obj.H0/2; %Approximate diffusion distance through the Adventitia (same units as H0)
        end
        function r = r(obj)
        	r = sqrt( ((pi-obj.phi0/2)/(pi*obj.cs.lz)) .* (obj.cs.R.^2-obj.Ri^2) + obj.cs.ri.^2 );
        end
        function obj = R(obj)
        	obj.cs.R = sqrt( ((pi*obj.cs.lz)/(pi-obj.phi0/2)) .* (obj.cs.r.^2-obj.cs.ri.^2) + obj.Ri^2  );
        end
        
        %Stretch Ratios
        function lr = lr(obj)
            lr = (pi-obj.phi0/2) .* obj.cs.R ./ (pi.*obj.cs.r.*obj.cs.lz);
        end
        function lz = lz(obj)
            lz = obj.cs.lambda*obj.Deltaz;
        end
        function lt = lt(obj)
            lt = (pi/(pi-obj.phi0/2)).*(obj.cs.r./obj.cs.R);
        end
        
        %Some Shortcuts
        function obj = ro(obj,N)
            %N=1 numeric
            if N
                obj.cs.ri = obj.cs.riNum;
            end
            obj.cs.R = obj.Ro;
            obj.cs.ro = obj.r;
            
            obj.cs.ri = obj.cs.riG;
            obj.R;
        end
        
        %Calculate ri
        function err = riCalc(obj)
            s = obj.cs.sECM + obj.cs.sSMC + obj.cs.sMMy;
            
            Sr = s(1,:); St = s(2,:); Sz = s(3,:);
            
            f = sum( ((St-Sr)./obj.cs.x).*obj.cs.w );
            
            if obj.cs.riNum
            	riNew = double(vpasolve(f == obj.cs.Pin,[0.9*obj.cs.riNum 1.1*obj.cs.riNum]));
            else
            	riNew = double(vpasolve(f == obj.cs.Pin,[0 2]));
            end
            
            if isempty(riNew)
                fprintf('Error calculating ri\n');
                err = 1;
            else
                obj.cs.riNum = riNew;
                obj.xwNum;
                obj.cs.FT = obj.FTCalc(Sr,St,Sz);
                
                obj.cs.r = obj.cs.xNum;
                obj.R;
                
                obj.cs.ltNum = obj.lt;
                obj.cs.lrNum = obj.lr;
                obj.cs.lzNum = obj.lz;
                
                if obj.ufs == 0
                    obj.ufs = sqrt( (obj.cs.lrNum.^2)*power(sin(obj.thetaSMC),2) + (obj.cs.ltNum.^2)*power(cos(obj.thetaSMC),2) );
                end
                
                obj.cs.r = obj.cs.x;
                obj.R;
                
                err = 0;
            end
        end
        
        function err = stepCalc(obj,i)
            %Current Step Myosin Fractions
            obj.nAMp = obj.nAMpVec(i);
            obj.nAM = obj.nAMVec(i);
            
            obj.xwNum;
            
            obj.cs.lr = obj.cs.lrNum;
            
            obj.LMi;
            obj.Lfoi;
            obj.eS2(1);
            obj.eS2(2);
            obj.cs.I4SMCeNum = obj.I4SMCe;
            obj.ufsUpdate;
            
            obj.cs.lr = obj.cs.x;
            
            obj.sSMC;
            obj.sMMy;
            
            if obj.riCalc
                fprintf('Error calculating ri\n');
                err = 1;
            else
                %rm = (obj.cs.riNum+obj.roNum)/2; %Middle radii
                
                %PMMCU = subs([obj.PMM,obj.PCU],obj.riNum);
                
                %obj.V.UpdateVectors(i,obj.cs);
                
                %fprintf('| Do=%.2f kPa | F_T=%.2f mN | ',obj.V.DoVec(i),obj.V.FTVec(i));
                err = 0;
            end
        end
        
        function [err] = InitialParameters(obj)
            obj.nCalc;
            
            obj.cs.ri = obj.cs.riG;

            obj.cs.lr = obj.lr;
            obj.cs.lt = obj.lt;
            obj.cs.lz = obj.lz; obj.cs.lzNum = obj.cs.lz;
                        
            obj.xw;
            
            obj.sECM;
            obj.cs.sSMC = zeros(size(obj.cs.sECM));
            obj.cs.sECM = zeros(size(obj.cs.sECM));
            
            if obj.riCalc
                fprintf('Error calculating ri\n');
                err = 1;
            else
                fprintf('Initial Passive Conditions: ');
                fprintf('Do=%.3f, lr=%.3f, lt=%.3f, lz=%.3f \n',obj.roNum*2e3,obj.lrNum(obj.riNum),obj.ltNum(obj.riNum),obj.lz);
                obj.V.InitialVectors(length(obj.timeVec),0);
                err = 0;
            end
        end
        
        function obj = nCalc(obj)
            function dydt = myode(t,y)
                k1 = obj.k1t(t);
                kM = [-k1, obj.k(2), 0, obj.k(7)
                    k1, -obj.k(2)-obj.k(3), obj.k(4), 0
                    0, obj.k(3), -obj.k(4)-obj.k(5), obj.k(6)
                    0, 0, obj.k(5), -obj.k(6)-obj.k(7)];
                dydt = kM*y;
            end
            [time, n] = ode15s(@(t,y) myode(t,y),0:obj.dt:obj.TotalTime*60,[1 0 0 0]);
            
            obj.V.timeVec = time./60;
            obj.V.nAMpVec = n(:,3); obj.V.nAMVec = n(:,4);
        end
        function k1t = k1t(obj,t)
            k1t = obj.k(1)*erfc( obj.hadv/(2*sqrt(obj.DKCL*t)) );
        end
        
        %Calculate Axial Force for a Given Stress
        function FT = FTCalc(obj,Sr,St,Sz)
            f = subs(2*Sz-St-Sr,obj.cs.riNum);
            FT = double( pi*sum((f.*obj.cs.xNum).*obj.cs.wNum) );
        end
        
        %Calculate Legendre Points and Weights
        function obj = xw(obj)
            obj.ro(0);
            [obj.cs.x,obj.cs.w] = lgwt(3,obj.cs.ri,obj.cs.ro);
        end
        function obj = xwNum(obj)
            obj.ro(1);
            [obj.cs.xNum,obj.cs.wNum] = lgwt(3,obj.cs.riNum,obj.cs.roNum);
        end
        
        %Some Additional Shortcuts for Results Analysis
        function ufsfit = ufsfit(obj,r)
            p = polyfit(obj.xwNum,obj.ufs,1);
            ufsfit = p(1).*r + p(2);
        end
        
        function obj = PlotResults(obj)
            figure(1);
            plot(obj.timeVec./60,obj.V.DoVec);
            grid on; ylim([600 1300]); xlim([0 obj.TotalTime]); %ylim([0 (ceil(max(obj.DoVec))+100)]);
            ylabel('Do (um)'); xlabel('time (min)');
            title(['lz=' num2str(obj.lz) ' Pin=' num2str(obj.Pin/133.322387415*1e6) ' mmHg']);
            
            figure(2);
            plot(obj.timeVec./60,obj.V.FTVec);
            minFT = min(obj.V.FTVec);
            maxFT = max(obj.V.FTVec);
            if minFT<0
                minFT = ceil(minFT-2);
            else
               minFT = 0; 
            end
            if maxFT<0
                maxFT = ceil(maxFT+2);
            else
                maxFT = 0;
            end
            grid on; ylim([minFT maxFT]); xlim([0 obj.TotalTime]);
            ylabel('F_T (mN)'); xlabel('time (min)');
            
            figure(3);
            plot(obj.timeVec./60,obj.V.stretchVec);
            grid on; ylim([0 2]); xlim([0 obj.TotalTime]);
            ylabel('Stretch Ratio'); xlabel('time (min)');
            legend('\lambda_r','\lambda_\theta','\lambda_z','det(F)');

            figure(4);
            plot(obj.timeVec./60,obj.V.PMMCUVec*1e3);
            ylabel('Stress (kPa)'); ylim([0 ceil(max(obj.V.PMMCUVec*1e3,[],'all')+10)]);
            hold on; yyaxis right;
            plot(obj.timeVec./60,obj.V.ufsVec);
            h = legend('$P_{MM}$','$P_{CU}$','$\bar{u}_{fs}$ (right axis)');
            ylabel('ufs'); xlabel('time (min)'); grid on; hold off;
            set(h,'Interpreter','latex','fontsize',12);   

%             figure(4);
%             plot(obj.timeVec./60, (obj.sECMVec+obj.sSMCVec+obj.sMMyVec)*1e3);
%             h = legend('${\sigma}_{r}$','${\sigma}_{\theta}$','${\sigma}_{z}$');
%             ylabel('Cauchy Stress (kPa)'); xlabel('time (min)'); grid on;
%             set(h,'Interpreter','latex','fontsize',12);
        end
    end
end
