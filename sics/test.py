import cv2
import numpy as np;
import matplotlib.pyplot as plt
 
# Read image
im = cv2.imread("/home/bhargav/Downloads/blob.png", cv2.IMREAD_GRAYSCALE)
retval, threshold = cv2.threshold(im, 20, 255, cv2.THRESH_BINARY_INV)

_,countours,hierarchy = cv2.findContours(threshold,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)

cv2.drawContours(im,countours,-1,(245,255,244),3)

plt.imshow(im, cmap='gray')
plt.show()