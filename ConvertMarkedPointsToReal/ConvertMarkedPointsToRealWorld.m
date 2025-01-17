%Titus John
%Leventhal Lab, University of Michigan
%9/1/15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%This call the diffrent CV function in order to convert the marked points
%into real world points

%Input
%This takes in the real 



%Output
%Outputs the triangulated 3 poitns 

%Flow of code from the raw input
% 1.) Take the image points from the dorsum view 
% 2.) Take the new orgin calculated using the undistort function and normalize the points
% 3.) Normalize the points to homogeneous points
% 4.) Shoot into triangulate_DL.

function  [points3d,reprojectedPoints,errors] = ConvertMarkedPointsToRealWorld(x1,x2,F,P1,P2)
    load('cameraParameters.mat');
    
    %Undistort the points
    x1 = undistortPoints(x1,cameraParams);
    x2 = undistortPoints(x2,cameraParams);
    
    %Grab the intrsic matrix
    k = cameraParams.IntrinsicMatrix;
    
    %Create homogenous  verions of the points
    x1_hom = [x1, ones(size(x1,1),1)]';
    x2_hom = [x2, ones(size(x2,1),1)]';
    
    %Normalize points
    x1_norm = (k' \ x1_hom)';   
    x2_norm = (k' \ x2_hom)';   
    
        
    %remove the homogenous from normalized points
    x1_norm(:,3) = [];
    x2_norm(:,3) = [];
    
      
    %Use the triangulation function 
    [points3d,reprojectedPoints,errors] = triangulate_DL(x1_norm, x2_norm, P1, P2); 
  
%     figure(4)
%     [J,newOrigin] = undistortImage(I,cameraParams);
%     imshow(J)
%     hold on
%     
%     
%     reprojectedPoints = allreprojectedPoints{1,1}; 
%     x1_reprojected = reprojectedPoints(:,:,1);
%     x2_reprojected = reprojectedPoints(:,:,2);
%     
%     x1_rp_hom = [x1_reprojected,ones(size(x1_reprojected,1),1)];
%     x2_rp_hom = [x2_reprojected,ones(size(x2_reprojected,1),1)];
%     x1_scaled = (k'* x1_rp_hom')';
%     x2_scaled = (k'* x2_rp_hom')';
%     x1_scaled = bsxfun(@rdivide,x1_scaled(:,1:2),x1_scaled(:,3));
%     x2_scaled = bsxfun(@rdivide,x2_scaled(:,1:2),x2_scaled(:,3));
%     
%     hold on
%     scatter(x1_scaled(:,1),x1_scaled(:,2))
%     scatter(x2_scaled(:,1),x2_scaled(:,2))
% %     
%     figure(5)
%     
%     
%     x1_reprojected = reprojectedPoints(:,:,1);
%     x2_reprojected = reprojectedPoints(:,:,2);
%     hold on 
%     
%     scatter(x1_reprojected(:,1),x1_reprojected(:,2),'r')
%     scatter(x2_reprojected(:,1),x2_reprojected(:,2),'b')
%     
%     x = points3d(:,1);
%     y = points3d(:,2);
%     z = points3d(:,3);
%     scatter3(x,y,z)
%     
%     xlim([-1,1])
%     ylim([-1,1])
%     zlim([-1,1])
%     
%     xlabel('x')
%     ylabel('y')
%     zlabel('z')
     
    
%     A = points3d(end-2,:);
%     B = points3d(end-1,:);
%     
%     a1 = A(:,1);
%     a2 = A(:,2);
%     a3 = A(:,3);
% 
%     b1 = B(:,1);
%     b2 = B(:,2);
%     b3 = B(:,3);
% 
%     dist1 =sqrt((a1-b1)^2+(a2-b2)^2+(a3-b3)^2);
%     
%     
%     A = points3d(end-4,:);
%     B = points3d(end-3,:);
%     
%     a1 = A(:,1);
%     a2 = A(:,2);
%     a3 = A(:,3);
% 
%     b1 = B(:,1);
%     b2 = B(:,2);
%     b3 = B(:,3);
%     
%     
%     dist2 =sqrt((a1-b1)^2+(a2-b2)^2+(a3-b3)^2);
%     
%      
%     A = points3d(end-6,:);
%     B = points3d(end-5,:);
%     
%     a1 = A(:,1);
%     a2 = A(:,2);
%     a3 = A(:,3);
% 
%     b1 = B(:,1);
%     b2 = B(:,2);
%     b3 = B(:,3);
%     
%     
%     dist3 =sqrt((a1-b1)^2+(a2-b2)^2+(a3-b3)^2);
%     
%     meanRubiksDist = (dist1+dist2+dist3)/3;
%     
%     
%     
%     pxToMm = 17.5 / meanRubiksDist; %17.5 mm is legnth of rubicks cube square
%     
end






