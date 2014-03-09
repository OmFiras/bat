function model = trainmodel_ssvm(name,pos,K,pa,sbin,tsize,kk,kkk,fix_def)

if nargin < 6
  tsize = [];
  kk = 100;
  kkk = 100;
  fix_def = 0;
end

globals;

file = [cachedir name '.log'];
delete(file);
diary(file);

%% initialization
% cls = [name '_cluster_' num2str(K')'];
% try
%   load([cachedir cls]);
% catch
  model = initmodel(pos,sbin,tsize);
  def = data_def(pos,model);
  idx = clusterparts(def,K,pa); % each part in each example has a cluster label
%   save([cachedir cls],'def','idx');
% end

%% train part filters independently
for p = 1:length(pa)
  cls = [name '_part_' num2str(p) '_mix_' num2str(K(p))];
  try
    load([cachedir cls]);
  catch
    %sneg = neg(1:min(length(neg),100));
    models = cell(1,K(p));
    for k = 1:K(p)
      spos = pos(idx{p} == k);
      for n = 1:length(spos)
        spos(n).x1 = spos(n).x1(p);
        spos(n).y1 = spos(n).y1(p);
        spos(n).x2 = spos(n).x2(p);
        spos(n).y2 = spos(n).y2(p);
      end
      model = initmodel(spos,sbin,tsize);
      warp = 1; debug = 0;
      [models{k},progress] = train_inner(cls,model,spos,warp,0,fix_def,debug);
    end
    % DEBUG code
    %visualizemodel(models{1})
    %norm(models{1}.w,2)
    %im = imread(pos(8).im);
    %[boxes] = detect_fast(im, models{1}, 0);
    %boxes = nms(boxes,0.3);
    %showboxes(im,boxes(1,:),{'g'})
    %pause;
    
    model = mergemodels(models); % merge mixtures
    save([cachedir cls],'model');
  end
end

%% build tree structure, determine anchor positions
cls = [name '_final1_' num2str(K')' '_' num2str(kk) '_' num2str(kkk) '_' num2str(fix_def)];
try
  load([cachedir cls]);
catch
  model = buildmodel(name,model,def,idx,K,pa); % combine parts
  model.w = model2vec(model);
  for p = 1:length(pa)
		for n = 1:length(pos)
			pos(n).mix(p) = idx{p}(n);
		end
  end
  warp = 0; debug = 0;
  model = train_inner(cls,model,pos,warp,kk,fix_def,debug);
  save([cachedir cls],'model');
  % DEBUG code
%   visualizemodel(model)
%   visualizeskeleton(model)
%   im = imread(pos(8).im);
%   [boxes] = detect_fast(im, model, 0);
%   boxes = nms(boxes,0.3);
%   showboxes(im,boxes(1,:),{'g','g','g','g','g','g','g','g','g','g','g','g','g'})
end

%% final round
cls = [name '_final_' num2str(K')' '_' num2str(kk) '_' num2str(kkk) '_' num2str(fix_def)];
try
  load([cachedir cls]);
catch
  if isfield(pos,'mix')
    pos = rmfield(pos,'mix');
  end
  warp = 0; debug = 0;
  model = train_inner(cls,model,pos,warp,kkk,fix_def,debug);
  save([cachedir cls],'model');
end