function ov = testoverlap(sizx,sizy,pyra,level,bbox,overlap)
% Compute a mask of filter reponse locations (for a filter of size sizy,sizx)
% that sufficiently overlap a ground-truth bounding box (bbox) 
% at a particular level in a feature pyramid

scale = pyra.scale(level);
padx  = pyra.padx;
pady  = pyra.pady;
[dimy,dimx,foo] = size(pyra.feat{level});

bx1 = bbox(1);
by1 = bbox(2);
bx2 = bbox(3);
by2 = bbox(4);

% Index windows evaluated by filter (in image coordinates)
x1 = ((1:dimx-sizx+1) - padx - 1)*scale + 1;
y1 = ((1:dimy-sizy+1) - pady - 1)*scale + 1;
x2 = x1 + sizx*scale - 1;
y2 = y1 + sizy*scale - 1;

% Compute intersection with bbox
xx1 = max(x1,bx1);
xx2 = min(x2,bx2);
yy1 = max(y1,by1);
yy2 = min(y2,by2);
w = xx2 - xx1 + 1;
h = yy2 - yy1 + 1;
w(w<0) = 0;
h(h<0) = 0;
inter  = h'*w;

% area of (possibly clipped) detection windows and original bbox
area = (y2-y1+1)'*(x2-x1+1);
box = (by2-by1+1)*(bx2-bx1+1);

% thresholded overlap
ov = inter ./ (area + box - inter) > overlap;

% output location
% [yy,xx] = find(ov == 1);
