//
//  main.m
//  Spectrum
//
//  Created by OS on 2019/5/5.
//  Copyright © 2019 Whde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
/*
#include <iostream>
#include <string>
#include <random>
*/
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
        /*
        const int nrolls=100;  // number of experiments
        const int nstars=100;    // maximum number of stars to distribute
        
        std::default_random_engine generator;
        std::cauchy_distribution<double> distribution(5.0,4.0);
        
        int p[10]={};
        
        for (int i=0; i<nrolls; ++i) {
            double number = distribution(generator);
            if ((number>=0.0)&&(number<10.0)) {
                 ++p[int(number)];
            }
        }
        for (int i=0; i<10; ++i) {
            std::cout << p[i] << std::endl;
            std::cout << std::string(p[i]*nstars/nrolls,'*') << std::endl;
        }
        */

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        
    }
}
