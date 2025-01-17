function [fullMask] = trackNextStep_direct(image_ud, prev_image_ud, BGimg_ud, prevMask, cur_mir_points2d,boxRegions, pawPref, fundMat, greenBGmask, varargin)

h = size(image_ud,1); w = size(image_ud,2);
targetMean = [0.5,0.2,0.5
              0.3,0.5,0.5];
    
targetSigma = [0.2,0.2,0.2
               0.2,0.2,0.2];
           
maxFrontPanelSep = 20;
maxDistPerFrame = 20;

numStretches = 2;

foregroundThresh = 45/255;
whiteThresh = 0.8;

shelfThick = 50;

frontPanelMask = boxRegions.frontPanelMask;
shelfMask = boxRegions.shelfMask;
% frontPanelEdge = imdilate(frontPanelMask, strel('disk',maxFrontPanelSep)) & ~frontPanelMask;
% shelfEdge = imdilate(shelfMask, strel('disk',maxFrontPanelSep)) & ~frontPanelMask;
intMask = boxRegions.intMask;
% extMask = boxRegions.extMask;
slotMask = boxRegions.slotMask;

[~,x] = find(slotMask);
centerPoly_x = [min(x),max(x),max(x),min(x),min(x)];
centerPoly_y = [1,1,h,h,1];
centerMask = poly2mask(centerPoly_x,centerPoly_y,h,w);
centerMask = imdilate(centerMask,strel('line',100,0));
distFromSlot = 150;
ROI = [centerPoly_x(1)-distFromSlot, 1, range(x)+2*distFromSlot, h-1];
centerShelfMask = centerMask & shelfMask;

belowShelfMask = boxRegions.belowShelfMask;
floorMask = boxRegions.floorMask;

boxFrontThick = 20;
maskDilate = 15;

full_bbox = [1 1 w-1 h-1];

% blob parameters for tight thresholding
restrictiveBlob = vision.BlobAnalysis;
restrictiveBlob.AreaOutputPort = true;
restrictiveBlob.CentroidOutputPort = true;
restrictiveBlob.BoundingBoxOutputPort = true;
restrictiveBlob.LabelMatrixOutputPort = true;
restrictiveBlob.MinimumBlobArea = 5;
restrictiveBlob.MaximumBlobArea = 10000;

for iarg = 1 : 2 : nargin - 9
    switch lower(varargin{iarg})
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'pawhsvrange',
            pawHSVrange = varargin{iarg + 1};
        case 'resblob',
            restrictiveBlob = varargin{iarg + 1};
        case 'stretchtol',
            stretchTol = varargin{iarg + 1};
        case 'boxfrontthick',
            boxFrontThick = varargin{iarg + 1};
        case 'maxdistperframe',
            maxDistPerFrame = varargin{iarg + 1};
        case 'whitethresh',
            whiteThresh = varargin{iarg + 1};
    end
end

shelfLims = regionprops(boxRegions.shelfMask,'boundingbox');

mirror_mask = false(h,w);
if ~isempty(cur_mir_points2d)
    for ii = 1 : size(cur_mir_points2d,1)
        mirror_mask(cur_mir_points2d(ii,2),cur_mir_points2d(ii,1)) = true;
    end
    mirror_mask = imfill(mirror_mask,'holes');
    projMask = projMaskFromTangentLines(mirror_mask, fundMat, [1 1 w-1 h-1], [h,w]);
    centerProjMask = projMask & centerMask;
else
    centerProjMask = imdilate(centerMask,strel('disk',150));    % expand center region because this is probably the rat walking up to the slot
end

abs_BGdiff = imabsdiff(image_ud, BGimg_ud);
% BGdiff_stretch = color_adapthisteq(abs_BGdiff);
% decorr_green_BG = decorrstretch(BGdiff_stretch,...
%                              'targetmean',targetMean(1,:),...
%                              'targetsigma',targetSigma(1,:));
im_masked = false(h,w);
for ii = 1 : 3
    im_masked = im_masked | (abs_BGdiff(:,:,ii) > foregroundThresh);
end

str_img = image_ud;

for ii = 1 : numStretches
    str_img = color_adapthisteq(str_img);
end
whiteMask = rgb2gray(str_img) > whiteThresh;

 decorr_green = decorrstretch(str_img);
 %,...
%                              'targetmean',targetMean(1,:),...
%                              'targetsigma',targetSigma(1,:));
%                          
decorr_green_hsv = rgb2hsv(decorr_green);

%Have too account for the dorsal and ventral surface of the paw when thresholding
pawHSVrange      = [1,.1,.85,1,.85,1; %Ventral Surface
                    .1,.1,.6,.75,.7,.85]; %Dorsal Surface


prevMask_dilate = imdilate(prevMask,strel('disk',maxDistPerFrame));
dil_mask = imdilate(prevMask,strel('line',10,90)) | imdilate(prevMask,strel('line',10,270));
shelf_overlap_mask = dil_mask & shelfMask;

behindPanelMask = mirror_mask & intMask;

if any(shelf_overlap_mask(:)) && any(behindPanelMask(:))   % previous paw mask is very close to the shelf
                                % AND the paw is behind the front panel
                                % therefore, check the other side of the
                                % shelf to see if the paw shows
                                % up there
    SE = strel('rectangle',[shelfThick + 50, 10]);
    prevMask_panel_dilate = imdilate(prevMask, SE);
else
    prevMask_panel_dilate = false(size(prevMask));
end





 greenHSVthresh = HSVthreshold(decorr_green_hsv,pawHSVrange(1,:));
% %greenHSVthresh = greenHSVthresh & ~greenBGmask;
% 
% projGreenThresh = greenHSVthresh & im_masked & (centerProjMask | prevMask_dilate | prevMask_panel_dilate);
% projGreenThresh = projGreenThresh & ~whiteMask;
% 
% %lib_HSVmask = HSVthreshold(decorr_green_hsv,pawHSVrange(2,:));
% %fullThresh = imreconstruct(projGreenThresh, lib_HSVmask);

%Titus edit to use rgb and epipole to identify the paw
pawRGBrange = [1.25, .2 ,.5, 1.1, .1,.2];
rgbmask = RGBthreshold(decorr_green, pawRGBrange);


% 
% figure(7)
% imshow(rgbmask);
% hold on
% scatter(mean(cur_mir_points2d(:,1)),mean(cur_mir_points2d(:,2)),'r') 
 
projRedThresh = rgbmask & centerMask;

%centroidMirror = [mean(cur_mir_points2d(:,1)),mean(cur_mir_points2d(:,2))]



%Get the fund Mat for the direct mirror %seems to be diffrent
load('fundMatDirectTemp.mat')

%This function identify if full thresh paw based on label
[fullThresh] = identfyPawBlobfromMirrorCentroid(projRedThresh,fundMatDirect,cur_mir_points2d,boxRegions,pawPref,rgbmask,image_ud);
 



bbox = [1,1,w-1,h-1];
bbox(2,:) = bbox;
if ~isempty(cur_mir_points2d) && any(fullThresh(:))
    masks{1} = fullThresh;
    masks{2} = mirror_mask;
    
    %Trying withouth estimation of hiddent silhouette
    fullMask{1} = masks{1};
    fullMask{2} = masks{2};
%    fullMask = estimateHiddenSilhouette(masks, bbox,fundMat,[h,w]);
elseif ~isempty(cur_mir_points2d) && ~any(fullThresh(:))
    fullMask{1} = false(h,w);
    fullMask{2} = mirror_mask;
elseif isempty(cur_mir_points2d) && any(fullThresh(:))
    fullMask{1} = fullThresh;
    fullMask{2} = false(h,w);
else
    fullMask{1} = false(h,w);
    fullMask{2} = false(h,w);
end