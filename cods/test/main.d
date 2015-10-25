import std.stdio;
import std.conv;
import std.container;
import core.thread;

import networkSimulator;
import cods;
import uc;


/**********************************
 *
 * User-defined data type
 *
 **********************************/


class Register(T) {
  private T t;
  public void opAssign(T t) {
    this.t = t;
  }
  public T read() {
    return t;
  }
}

/**********************************
 *
 * Transaction declaration
 *
 **********************************/

class TransXY(CC) : Transaction!void {
  public override void execute() {
    Register!int x = UC.connect!(Register!int)("x");
    Register!int y = UC.connect!(Register!int)("y");
    y = 10 * x.read();
  }
}


/**********************************
 *
 * Code for the first process
 *
 **********************************/


void p1 () { 

  /*
   * Data connection
   **************************/

  Register!int x = UC.connect!(Register!int)("x");
  Register!int y = UC.connect!(Register!int)("y");

  /*
   * Simple method calls
   **************************/

  x = 1;       writeln("* x := 1");
  y = 2;       writeln("* y := 2");

  writeln("  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");

  /*
   * Anonymous transactions
   **************************/

  UC.anonymousTransaction({
    x = 5;
    y = 6;
    x = 7;
  });
  writeln("* {x := 5; y := 6; x := 7}");

  writeln("  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");

  /*
   * Convergence
   **************************/

  Thread.sleep(dur!("msecs")(1000));
  writeln("  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");
}


/**********************************
 *
 * Code for the second process
 *
 **********************************/

void p2 () {  

  /*
   * Data Connection
   **************************/
  Register!int x = UC.connect!(Register!int)("x");
  Register!int y = UC.connect!(Register!int)("y");

  /*
   * Simple method calls
   **************************/

  x = 3;       writeln("\t\t\t\t* x := 3");
  y = 4;       writeln("\t\t\t\t* y := 4");

  writeln("\t\t\t\t  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");

  /*
   * Named transactions
   **************************/

  UC.transaction!void(new TransXY!UC()); 
  writeln("\t\t\t\t* y := 10*x");

  writeln("\t\t\t\t  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");

  /*
   * Convergence
   **************************/

  Thread.sleep(dur!("msecs")(500));
  writeln("\n---------------------------------------------\n");
  Thread.sleep(dur!("msecs")(500));
  writeln("\t\t\t\t  (x=" ~ to!string(x.read()) ~ ", y=" ~ to!string(y.read()) ~ ")");
}


/**********************************
 *
 * Main program
 *
 **********************************/


void main () 
{ 
  Network.registerType!(TransXY!UC);
  auto network = new NetworkSimulator!2([
    {
      p1();
    }, {
      p2();
    }]);
  Network.configure(network);
  network.start();
}

