## svg ratios, resolutions

 * 1:1   512x512  country-squared inset: ~403x403  ratio 1.0
 * 1.451 1280x960 country-4x2     inset: ~1068x736 ratio 1.451
 * 1365x512 country-4x3     inset: 

## inset borders and ratios

left + right border = 512 - 403 = 109

border width = 109 / 2   = 54.5

 * 1:1   403x403
 * 4:2   806x403
 * 4:3   537x403

## pixel perfect template resolutions

 * 1:1 width = 512; border = 54.5;            height = 512
 
   Optimal resolution: width = 512          ; height = 512

 * 4:2 height = 512; border = 54.5; width = 403 * (4/2) + 2 * 54.5 = 915.00
 
   Optimal resolution: width = 915;         ; height = 512

 * 4:3 height = 512; border = 54.5; width = 403 * (4/3) + 2 * 54.5 = 646.33333
 
   Optimal resolution: width = 646.33333 * 3; height = 512 * 3;
                       width = 1939         ; height = 1536
					   
					   
