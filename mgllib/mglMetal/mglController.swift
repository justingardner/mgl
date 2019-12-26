//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglController.swift
//  mglStandaloneDisplay
//
//  Created by justin gardner on 12/25/2019.
//  Copyright © 2019 GRU. All rights reserved.
//  Purpose: Controls the connection between matlab and
//           the display. Reads commands from mglComm
//           and handles executing the commands by
//           passing them to mglDisplay
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

import Foundation

class mglController {

    var comm : mglCommSocket!
    var display : mglDisplay!
    // FIX, make this private
    var profileMode = false
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init() {
    }
    convenience init (inputComm : mglCommSocket, inputDisplay : mglDisplay) {
        self.init()
        // keep references to the comm and display
        comm = inputComm
        display = inputDisplay
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // update - runs the show
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func update() {
        if (comm.dataWaiting()) {
            let command = comm.readCommand();
            // ping command
            switch command {
                // FIX, this should be mglCommCommands enum, but swift does not recogonize
                case 0:
                    print("(mglController:update) Ping");
                case 1:
                    print("(mglController:update) Draw");
                    // draw something to the screen
                    display.draw()
                case 2:
                    print("(mglController:update) Profile mode on");
                    profileMode = true;
                case 3:
                    print("(mglController:update) Profile mode off");
                    profileMode = false;
                case 4:
                    print("(mglController:update) Receive UINT8 data");
                    let len = comm.readUINT32()
                    let data = comm.readData(len,dataType: mglDataType.kUINT32)
                    //var dataArray: [UInt32] = [] data.withUnsafeBytes
                    //var dataArray: NSInteger;
                    //data.getBytes(&dataArray, 4);
                    
                    print(len)
                    print("\(data)")
                    comm.writeDoubleHuh
                    profileMode = false;
                default:
                    //print("(mglComm:readCommand) Unknown command %i",command);
                    print("(mglComm:readCommand) Unknown command");
            }
        }
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // deinit
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    deinit {
        // close the communication port
        comm.close()
    }
}
