import cods;
class PC_Message : Message {
  private int id, cl;
  private Operation op;
  this(int mId, int mCl, Operation mOp) {id=mId; cl=mCl; op=mOp; }
  override void on_receive() {
    PC.getInstance().getImplementation().receiveMessage(id, cl, op);
  }
}
class PC_Implementation : ConsistencyCriterionImplementation {
  private int[int] clock;
  private Operation[int][int] pending;
  this() {
    Network.registerType!PC_Message;
    clock = [Network.getInstance().getID() : 0];
  }
  ExtObject executeOperation(Operation op) {
    int id = Network.getInstance().getID();
    ExtObject o = op.execute();
    clock[id] = clock[id]+1;
    Message m = new PC_Message(id, clock[id], op);
    Network.getInstance().broadcast(m); // Écriture
    return o;
  }
  void receiveMessage(int mId, int mCl, Operation mOp) {
    if(!(mId in clock)) clock[mId] = 0;
    if (clock[mId] < mCl) {
      pending[mId][mCl] = mOp; 
      for(int cl = clock[mId] + 1; cl in pending[mId]; cl++){
//      foreach(int cl; pending[mId].keys.sort){
//        if(cl != clock[mId] + 1) break;
        clock[mId] = cl;
        pending[mId][cl].execute();
        pending[mId].remove(cl);
      }
    } // else : old message received twice - dropped
  }
  override static public class SharedObject(T) : ConsistencyCriterionImplementation.SharedObject!T {
    T t = new T();
    override public ExtObject executeMethod(Functor!T f) {
      return f.execute(t);
    }
  }
}
class PC : ConsistencyCriterionBase!PC_Implementation {};
