import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CardApp());
class CardApp extends StatelessWidget { const CardApp({super.key}); @override Widget build(BuildContext context) => const MaterialApp(debugShowCheckedModeBanner: false, home: AuthCheck()); }

class AppCard {
  String id, number, holder, expiry, cvv; double balance; Color c1, c2;
  AppCard({required this.id, required this.number, required this.holder, required this.expiry, required this.cvv, required this.balance, required this.c1, required this.c2});
  Map toJson() => {'id':id,'number':number,'holder':holder,'expiry':expiry,'cvv':cvv,'balance':balance,'c1':c1.value,'c2':c2.value};
  static AppCard fromJson(Map j) => AppCard(id:j['id'], number:j['number'], holder:j['holder'], expiry:j['expiry'], cvv:j['cvv'], balance:(j['balance'] as num).toDouble(), c1:Color(j['c1']), c2:Color(j['c2']));
}
class AppUser {
  String email, pass, name, phone, address, city, zip; bool keepOpen; List<AppCard> cards; List<Map<String,dynamic>> history;
  AppUser({required this.email, required this.pass, required this.name, this.phone="(617) 555-0142", this.address="15 Tremont St", this.city="Boston, MA", this.zip="02108", this.keepOpen=true, required this.cards, this.history=const []});
  Map toJson() => {'email':email,'pass':pass,'name':name,'phone':phone,'address':address,'city':city,'zip':zip,'keepOpen':keepOpen,'cards':cards.map((e)=>e.toJson()).toList(),'history':history};
  static AppUser fromJson(Map j) => AppUser(email:j['email'], pass:j['pass'], name:j['name'], phone:j['phone']??"(617) 555-0142", address:j['address']??"15 Tremont St", city:j['city']??"Boston, MA", zip:j['zip']??"02108", keepOpen:j['keepOpen']??true, cards:(j['cards'] as List).map((e)=>AppCard.fromJson(e)).toList(), history: (j['history'] as List?)?.map((e)=>Map<String,dynamic>.from(e)).toList()??[]);
}
class Storage {
  static Future<void> saveUser(AppUser u) async { final p = await SharedPreferences.getInstance(); List<String> users = p.getStringList('users')?? []; users.removeWhere((e)=> jsonDecode(e)['email']==u.email); users.add(jsonEncode(u.toJson())); await p.setStringList('users', users); await p.setString('current', u.email); }
  static Future<AppUser?> getCurrent() async { final p = await SharedPreferences.getInstance(); String? cur = p.getString('current'); if(cur==null) return null; List<String> users = p.getStringList('users')?? []; for(var s in users){ var j=jsonDecode(s); if(j['email']==cur) return AppUser.fromJson(j); } return null; }
  static Future<void> logout() async { final p = await SharedPreferences.getInstance(); await p.remove('current'); }
  static Future<void> clearAll() async { final p = await SharedPreferences.getInstance(); await p.clear(); }
}

// AUTH CHECK CON LOGICA DE KEEP OPEN
class AuthCheck extends StatefulWidget{ const AuthCheck({super.key}); @override State<AuthCheck> createState()=>_AuthCheckState(); }
class _AuthCheckState extends State<AuthCheck>{
  bool locked=true;
  @override Widget build(BuildContext context){
    return FutureBuilder<AppUser?>(future: Storage.getCurrent(), builder: (c,s){
      if(s.connectionState==ConnectionState.waiting) return const Scaffold(backgroundColor:Colors.black, body:Center(child:CircularProgressIndicator(color:Color(0xFFB537F2))));
      if(s.data==null) return const LoginScreen(); // No tiene cuenta -> crear una

      // Si tiene cuenta pero keepOpen es false -> se cierra la sesion automaticamente y vuelve a login
      AppUser user = s.data!;
      if(!user.keepOpen && locked){
        // Si keepOpen OFF, no pide huella, entra directo pero la proxima vez que abra la app se cerrara si no lo activa
        // Para simular "se sierra", si keepOpen es false y viene de cerrar la app, mostramos login
        // Aqui: si keepOpen false, no bloqueamos con huella
        locked = false;
      }

      if(locked && user.keepOpen) return Scaffold(
        body: Stack(children:[
          const AnimatedBackground(mouseX: 0.5, mouseY: 0.5),
          Center(child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
            Container(padding:const EdgeInsets.all(20), decoration:BoxDecoration(color:const Color(0xFFB537F2).withOpacity(0.2), shape:BoxShape.circle), child:const Icon(Icons.fingerprint, size:80, color:Color(0xFFB537F2))),
            const SizedBox(height:20),
            Text("Welcome back, ${user.name.split(' ')[0]}", style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:22)),
            const Text("Boston • Touch ID to continue", style:TextStyle(color:Colors.white54)),
            const SizedBox(height:30),
            ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(30)), padding:const EdgeInsets.symmetric(horizontal:40, vertical:16)), onPressed:(){ HapticFeedback.heavyImpact(); setState(()=> locked=false); }, child:const Text("Unlock with Fingerprint", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900))),
            const SizedBox(height:20),
            TextButton(onPressed:() async { await Storage.logout(); if(context.mounted) setState(()=> locked=true); }, child:const Text("Use different account", style:TextStyle(color:Colors.white24, fontSize:11))),
          ])),
        ]),
      );
      return CashHome(user:user);
    });
  }
}

class LoginScreen extends StatelessWidget { const LoginScreen({super.key}); @override Widget build(BuildContext context){
  final email=TextEditingController(), name=TextEditingController();
  return Scaffold(body: Stack(children:[
    const AnimatedBackground(mouseX: 0.5, mouseY: 0.3),
    Padding(padding:const EdgeInsets.all(28), child:Column(mainAxisAlignment:MainAxisAlignment.center, crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[const Icon(Icons.cloud, color:Color(0xFFB537F2), size:18), const SizedBox(width:6), const Text("Boston, MA • 72°F ☀️ Sunny", style:TextStyle(color:Color(0xFFB537F2), fontSize:11, fontWeight:FontWeight.bold))]),
      const SizedBox(height:12),
      const Text("Boston\nCash", style:TextStyle(fontSize:48, fontWeight:FontWeight.w900, color:Colors.white, height:0.9, shadows:[Shadow(color:Color(0xFFB537F2), blurRadius:20)])),
      const SizedBox(height:8),
      const Text("FDIC Insured • Bank of America Boston", style:TextStyle(color:Colors.white38, fontSize:10)),
      const SizedBox(height:30),
      TextField(controller:name, style:const TextStyle(color:Colors.white), decoration:InputDecoration(hintText:"Full Name", filled:true, fillColor:Colors.white.withOpacity(0.08), border:OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none))),
      const SizedBox(height:10),
      TextField(controller:email, style:const TextStyle(color:Colors.white), decoration:InputDecoration(hintText:"Email", filled:true, fillColor:Colors.white.withOpacity(0.08), border:OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none))),
      const SizedBox(height:20),
      SizedBox(width:double.infinity, height:56, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2), shadowColor:const Color(0xFFB537F2), elevation:12), onPressed:() async { var u=AppUser(email:email.text.isEmpty?"braylin@boston.com":email.text, pass:"123", name:name.text.isEmpty?"Braylin Estevez":name.text, keepOpen:true, cards:[AppCard(id:"1", number:"4242 4242 4242 0371", holder:(name.text.isEmpty?"BRAYLIN ESTEVEZ":name.text).toUpperCase(), expiry:"12/28", cvv:"123", balance:22863, c1:const Color(0xFF1A0A2E), c2:const Color(0xFFB537F2))], history:[{"name":"TD Garden ATM","type":"withdraw","amount":-120.0,"time":"2h ago","note":"Boston"},{"name":"Starbucks Boston","type":"pay","amount":-8.5,"time":"5h ago","note":"Downtown"},{"name":"Cash Added","type":"add","amount":500.0,"time":"Yesterday","note":"Boston Office"}]); await Storage.saveUser(u); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>const AuthCheck())); }, child:const Text("Create Account • Boston →", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900)))),
      const SizedBox(height:12),
      const Center(child:Text("Si ya tienes cuenta, se guardará y pedirá huella al iniciar", style:TextStyle(color:Colors.white24, fontSize:9))),
    ])),
  ]));
}}

class AnimatedBackground extends StatefulWidget {
  final double mouseX, mouseY;
  const AnimatedBackground({super.key, this.mouseX=0.5, this.mouseY=0.5});
  @override State<AnimatedBackground> createState()=>_AnimatedBackgroundState();
}
class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin{
  late AnimationController _ctrl;
  @override void initState(){ super.initState(); _ctrl=AnimationController(vsync:this, duration:const Duration(seconds: 10))..repeat(); }
  @override void dispose(){ _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return AnimatedBuilder(animation:_ctrl, builder:(c,_){
      return Container(width: double.infinity, height: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-1 + sin(_ctrl.value*2*pi)*0.4 + widget.mouseX*0.3, -1 + widget.mouseY*0.3), end: Alignment(1 + cos(_ctrl.value*2*pi)*0.4, 1), colors: const [Color(0xFF000000), Color(0xFF0D0620), Color(0xFF1A0A2E), Color(0xFF000000)])),
        child: Stack(children:[
          Positioned(left: -100 + sin(_ctrl.value*2*pi + widget.mouseX)*180, top: 80 + cos(_ctrl.value*2*pi)*100 + widget.mouseY*50, child: Container(width:320, height:320, decoration:BoxDecoration(shape:BoxShape.circle, color:const Color(0xFFB537F2).withOpacity(0.4), boxShadow:[BoxShadow(color:const Color(0xFFB537F2).withOpacity(0.7), blurRadius:100, spreadRadius:10)]))),
          Positioned(right: -60 + cos(_ctrl.value*2*pi*1.2)*140, top: 280 + sin(_ctrl.value*2*pi)*120, child: Container(width:260, height:260, decoration:BoxDecoration(shape:BoxShape.circle, color:const Color(0xFFFF00C8).withOpacity(0.3), boxShadow:[BoxShadow(color:const Color(0xFFFF00C8).withOpacity(0.6), blurRadius:90)]))),
          Positioned(left: 30 + sin(_ctrl.value*2*pi*0.7)*120, bottom: 80 + cos(_ctrl.value*2*pi)*80, child: Container(width:360, height:360, decoration:BoxDecoration(shape:BoxShape.circle, color:const Color(0xFF00D9FF).withOpacity(0.25), boxShadow:[BoxShadow(color:const Color(0xFF00D9FF).withOpacity(0.5), blurRadius:110)]))),
        ]),
      );
    });
  }
}

class CashHome extends StatefulWidget{ final AppUser user; const CashHome({super.key, required this.user}); @override State<CashHome> createState()=>_CashState(); }
class _CashState extends State<CashHome> with SingleTickerProviderStateMixin{
  late AppUser user; int cardIdx=0; int navIdx=0; double mx=0.5, my=0.5; bool showConfetti=false; late AnimationController confettiCtrl;
  @override void initState(){super.initState(); user=widget.user; confettiCtrl=AnimationController(vsync:this, duration:const Duration(seconds:2));}
  @override void dispose(){ confettiCtrl.dispose(); super.dispose(); }
  double get total => user.cards.fold(0, (s,c)=>s+c.balance);
  void save() async { await Storage.saveUser(user); setState((){}); }
  void triggerConfetti(){ setState(()=> showConfetti=true); confettiCtrl.forward(from:0); HapticFeedback.heavyImpact(); Future.delayed(const Duration(seconds:2), ()=> setState(()=> showConfetti=false)); }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: Colors.black, body: MouseRegion(onHover:(e){ setState((){ mx=e.position.dx/MediaQuery.of(context).size.width; my=e.position.dy/MediaQuery.of(context).size.height; }); }, child: Stack(children:[
        AnimatedBackground(mouseX: mx, mouseY: my),
        SafeArea(child: IndexedStack(index: navIdx, children:[_home(), _activityBoston(), _cardTab(), _qrAndAtm(), _bankBoston()])),
        if(showConfetti)...List.generate(30, (i)=> AnimatedBuilder(animation:confettiCtrl, builder:(c,_){
          double t=confettiCtrl.value; double x=(i*37%MediaQuery.of(context).size.width); double y= -50 + t*MediaQuery.of(context).size.height*1.2 + sin(t*10+i)*20;
          return Positioned(left:x, top:y, child: Container(width:8, height:8, decoration:BoxDecoration(color:[const Color(0xFFB537F2), const Color(0xFFFF00C8), const Color(0xFF00D9FF), Colors.white][i%4], shape:BoxShape.circle)));
        })),
      ])), bottomNavigationBar: Container(margin:const EdgeInsets.fromLTRB(12,0,12,16), height:64, decoration:BoxDecoration(color:Colors.white.withOpacity(0.07), borderRadius:BorderRadius.circular(32), border:Border.all(color:Colors.white.withOpacity(0.12))), child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[_nav(Icons.home,0), _nav(Icons.bar_chart,1), _nav(Icons.credit_card,2), _nav(Icons.qr_code,3), _nav(Icons.person,4)])),
    );
  }
  Widget _nav(IconData ic,int idx)=> IconButton(onPressed:()=>setState(()=>navIdx=idx), icon:Icon(ic, size:20, color: navIdx==idx? const Color(0xFFB537F2):Colors.white38));
  Widget _home(){
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(18), child: Column(children:[
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[ Row(children:[const CircleAvatar(radius:16, backgroundImage:AssetImage("assets/foto.jpg")), const SizedBox(width:8), Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(user.name, style:const TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:12)), const Row(children:[Icon(Icons.cloud, size:10, color:Color(0xFFB537F2)), SizedBox(width:4), Text("Boston 72°F • Sunny", style:TextStyle(color:Color(0xFFB537F2), fontSize:9))])])]), Row(children:[IconButton(onPressed:()=>_editProfile(), icon:const Icon(Icons.edit, size:16, color:Color(0xFFB537F2))), const Icon(Icons.notifications, size:16, color:Colors.white54)]) ]),
      const SizedBox(height:14), Center(child: SizedBox(width: 300, height: 180, child: Card3DWidget(card:user.cards[cardIdx], onTap:triggerConfetti))),
      const SizedBox(height:14), Text("\$${total.toStringAsFixed(2)}", style:const TextStyle(fontSize:32, fontWeight:FontWeight.w900, color:Colors.white, shadows:[Shadow(color:Color(0xFFB537F2), blurRadius:20)])), const Text("Cash Balance • Boston, MA • FDIC Insured", style:TextStyle(color:Colors.white60, fontSize:10)), const SizedBox(height:12), _spendingGraph(), const SizedBox(height:14),
      Row(children:[_btn("Add Cash", Icons.add, ()=>_sheet(isAdd:true)), const SizedBox(width:8), _btn("Cash Out", Icons.arrow_outward, ()=>_sheet(isAdd:false))]), const SizedBox(height:8),
      Row(children:[_btn("Send", Icons.arrow_upward, ()=>_sendMoney()), const SizedBox(width:8), _btn("Request", Icons.arrow_downward, ()=>_sendMoney(isRequest:true))]),
    ])));
  }
  Widget _btn(String t, IconData ic, VoidCallback f)=> Expanded(child:Container(height:46, decoration:BoxDecoration(color:Colors.white.withOpacity(0.08), borderRadius:BorderRadius.circular(12), border:Border.all(color:const Color(0xFFB537F2).withOpacity(0.2))), child:InkWell(borderRadius:BorderRadius.circular(12), onTap:(){ HapticFeedback.lightImpact(); f(); }, child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(ic, size:14, color:const Color(0xFFB537F2)), const SizedBox(width:4), Text(t, style:const TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.bold))]))));
  Widget _spendingGraph(){ return Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(16), border:Border.all(color:Colors.white.withOpacity(0.08))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Text("Spending • Boston", style:TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.bold)), Text("This Week", style:TextStyle(color:Color(0xFFB537F2), fontSize:9))]), const SizedBox(height:10), SizedBox(height:50, child: Row(crossAxisAlignment:CrossAxisAlignment.end, children: List.generate(7, (i){ double h=[0.4,0.7,0.3,0.9,0.6,0.8,0.5][i]; return Expanded(child: Container(margin:const EdgeInsets.symmetric(horizontal:3), height:50*h, decoration:BoxDecoration(color: i==3? const Color(0xFFB537F2): Colors.white.withOpacity(0.15), borderRadius:BorderRadius.circular(6), boxShadow: i==3? [BoxShadow(color:const Color(0xFFB537F2).withOpacity(0.6), blurRadius:10)]:null))); }))), ])); }
  void _sendMoney({bool isRequest=false}){
    String amount="0"; int step=0; TextEditingController toCtrl=TextEditingController(), cashTagCtrl=TextEditingController(), noteCtrl=TextEditingController(), fromCtrl=TextEditingController(text:"Bank of America • Boston **** 0371");
    showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.transparent, builder:(_){
      return StatefulBuilder(builder:(context,setM){
        return Container(height: MediaQuery.of(context).size.height*0.92, decoration: const BoxDecoration(color: Color(0xFF0F0F0F), borderRadius: BorderRadius.vertical(top: Radius.circular(28))), padding: EdgeInsets.fromLTRB(20,12,20, MediaQuery.of(context).viewInsets.bottom+20),
          child: step==0? Column(children:[ Container(width:32,height:4,decoration:BoxDecoration(color:Colors.white24, borderRadius:BorderRadius.circular(4))), const SizedBox(height:12), Text(isRequest?"Request":"Send • Cha-Ching 🔊", style:const TextStyle(color:Colors.white54, fontSize:11)), Text("\$$amount", style:TextStyle(fontSize:56, fontWeight:FontWeight.w900, color: amount=="0"? Colors.white24: Colors.white)), const Spacer(),
            GridView.builder(shrinkWrap:true, gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3, childAspectRatio:1.2, crossAxisSpacing:10, mainAxisSpacing:10), itemCount:12, itemBuilder:(c,i){ String lb=["1","2","3","4","5","6","7","8","9",".","0","⌫"][i]; return Material(color:const Color(0xFF1C1C1C), borderRadius:BorderRadius.circular(14), child:InkWell(borderRadius:BorderRadius.circular(14), onTap:(){ HapticFeedback.selectionClick(); setM((){ if(lb=="⌫"){ if(amount.length>1) amount=amount.substring(0,amount.length-1); else amount="0"; } else { if(amount=="0"&&lb!=".") amount=lb; else { if(lb=="."&&amount.contains(".")) return; if(amount.length<7) amount+=lb; } } }); }, child:Center(child: lb=="⌫"? const Icon(Icons.backspace_outlined, color:Colors.white54, size:20): Text(lb, style:const TextStyle(color:Colors.white, fontSize:22, fontWeight:FontWeight.bold))))); }),
            const SizedBox(height:14), SizedBox(width:double.infinity, height:54, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))), onPressed:(){ if((double.tryParse(amount)??0)<=0) return; setM(()=> step=1); }, child:Text("Continue • \$${amount}", style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900)))),
          ]) : SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Center(child:Container(width:32,height:4,decoration:BoxDecoration(color:Colors.white24, borderRadius:BorderRadius.circular(4)))), Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[ IconButton(onPressed:()=> setM(()=> step=0), icon:const Icon(Icons.arrow_back, color:Colors.white)), Text("\$$amount", style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:18)), const SizedBox(width:40), ]), const SizedBox(height:8), Text(isRequest?"Request \$${amount} from":"Send \$${amount} to", style:const TextStyle(color:Colors.white, fontSize:20, fontWeight:FontWeight.w900)), const SizedBox(height:14),
            _sendField(toCtrl, "TO", "Name, Phone, Email", Icons.person_outline), const SizedBox(height:8), _sendField(cashTagCtrl, "CASHTAG", "\$boston_cash", Icons.alternate_email), const SizedBox(height:8), _sendField(noteCtrl, "FOR", "Dinner in Seaport...", Icons.chat_bubble_outline), const SizedBox(height:8), _sendField(fromCtrl, "FROM", "Boston Account", Icons.account_balance), const SizedBox(height:14),
            SizedBox(width:double.infinity, height:54, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2), elevation:10, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))), onPressed:(){ if(toCtrl.text.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Escribe a quién"), backgroundColor:Colors.red)); return; } double m=double.tryParse(amount)??0; if(user.cards[cardIdx].balance < m){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Fondos insuficientes"))); return; } user.cards[cardIdx].balance-=m; user.history.insert(0, {"name":toCtrl.text, "type":"pay", "amount":-m, "time":"Just now", "note":noteCtrl.text.isEmpty?"Boston":noteCtrl.text}); save(); Navigator.pop(context); triggerConfetti(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("🔊 Cha-Ching! ✅ Sent \$$amount to ${toCtrl.text}"), backgroundColor:const Color(0xFFB537F2))); }, child:Text("Pay \$${amount} 🔊", style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900)))),
          ])),
        );
      });
    });
  }
  Widget _sendField(TextEditingController c, String label, String hint, IconData ic){ return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Text(label, style:const TextStyle(color:Color(0xFFB537F2), fontSize:9, fontWeight:FontWeight.w900)), const SizedBox(height:4), TextField(controller:c, style:const TextStyle(color:Colors.white, fontSize:13), decoration:InputDecoration(prefixIcon:Icon(ic, color:const Color(0xFFB537F2), size:16), hintText:hint, hintStyle:const TextStyle(color:Colors.white24, fontSize:11), filled:true, fillColor:const Color(0xFF1A1A1A), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none), focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:const BorderSide(color:Color(0xFFB537F2))), contentPadding:const EdgeInsets.symmetric(horizontal:12, vertical:12))), ]); }
  Widget _activityBoston(){ return ListView(padding:const EdgeInsets.all(18), children:[ const Text("Activity • Boston", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:20)), const SizedBox(height:6), const Text("Recent transactions in Boston, MA", style:TextStyle(color:Colors.white54, fontSize:11)), const SizedBox(height:14),...user.history.map((h)=> _tileHistory(h)).toList(), ]); }
  Widget _tileHistory(Map<String,dynamic> h){ double amt = (h['amount'] as num).toDouble(); bool isUp = amt > 0; return Container(margin:const EdgeInsets.only(bottom:8), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(14)), child:Row(children:[ const CircleAvatar(radius:18, backgroundImage:AssetImage("assets/foto.jpg"), backgroundColor:Colors.black), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(h['name']??"Unknown", style:const TextStyle(color:Colors.white, fontSize:12, fontWeight:FontWeight.bold)), Text("${h['time']} • ${h['note']??'Boston'}", style:const TextStyle(color:Colors.white54, fontSize:10))])), Column(crossAxisAlignment:CrossAxisAlignment.end, children:[Text("\$${amt.abs().toStringAsFixed(2)}", style:TextStyle(color:isUp?const Color(0xFFB537F2):Colors.white, fontWeight:FontWeight.bold, fontSize:12)), Text(isUp?"Received":"Sent", style:TextStyle(color:isUp?const Color(0xFFB537F2):Colors.white54, fontSize:9))]), ])); }
  Widget _qrAndAtm(){ return ListView(padding:const EdgeInsets.all(18), children:[ const Text("Boston QR & ATMs", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:18)), const SizedBox(height:14), Container(padding:const EdgeInsets.all(16), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(20)), child:Column(children:[ const Text("My Boston QR Code", style:TextStyle(color:Colors.black, fontWeight:FontWeight.w900)), const SizedBox(height:10), Container(width:180, height:180, decoration:BoxDecoration(color:Colors.black, borderRadius:BorderRadius.circular(12)), child: GridView.builder(gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:10), itemCount:100, itemBuilder:(c,i)=> Container(margin:const EdgeInsets.all(1), color: Random().nextBool()? Colors.white: Colors.black))), const SizedBox(height:10), Text(user.name, style:const TextStyle(color:Colors.black, fontWeight:FontWeight.bold)), Text("\$${user.name.toLowerCase().replaceAll(' ', '')}_boston", style:const TextStyle(color:Color(0xFFB537F2), fontWeight:FontWeight.w900)), ])), const SizedBox(height:16), const Text("ATMs Near Boston", style:TextStyle(color:Color(0xFFB537F2), fontWeight:FontWeight.w900, fontSize:11)), const SizedBox(height:8), _atmTile("Bank of America", "100 Federal St, Boston • 0.2 mi", "Free"), _atmTile("TD Garden ATM", "150 Causeway St • 0.5 mi", "\$3 fee"), ]); }
  Widget _atmTile(String name, String addr, String fee)=> Container(margin:const EdgeInsets.only(bottom:8), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(12)), child:Row(children:[Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:const Color(0xFFB537F2).withOpacity(0.15), borderRadius:BorderRadius.circular(8)), child:const Icon(Icons.atm, color:Color(0xFFB537F2), size:16)), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(name, style:const TextStyle(color:Colors.white, fontSize:12, fontWeight:FontWeight.bold)), Text(addr, style:const TextStyle(color:Colors.white54, fontSize:10))])), Container(padding:const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration:BoxDecoration(color:fee=="Free"? const Color(0xFFB537F2).withOpacity(0.2): Colors.white10, borderRadius:BorderRadius.circular(8)), child:Text(fee, style:TextStyle(color:fee=="Free"? const Color(0xFFB537F2): Colors.white54, fontSize:9, fontWeight:FontWeight.bold)))] ));
  void _editProfile(){ var n=TextEditingController(text:user.name); var e=TextEditingController(text:user.email); var p=TextEditingController(text:user.phone); var a=TextEditingController(text:user.address); showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.transparent, builder:(_)=> Container(padding:EdgeInsets.fromLTRB(20,12,20, MediaQuery.of(context).viewInsets.bottom+20), decoration:const BoxDecoration(color:Color(0xFF121212), borderRadius:BorderRadius.vertical(top:Radius.circular(24))), child:Column(mainAxisSize:MainAxisSize.min, children:[ Container(width:32,height:4,decoration:BoxDecoration(color:Colors.white24, borderRadius:BorderRadius.circular(4))), const SizedBox(height:12), const Text("Edit Profile - Boston", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900)), const SizedBox(height:12), _edit(n, "Full Name"), const SizedBox(height:8), _edit(e, "Email"), const SizedBox(height:8), _edit(p, "Phone"), const SizedBox(height:8), _edit(a, "Boston Address"), const SizedBox(height:14), SizedBox(width:double.infinity, height:48, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2)), onPressed:(){ setState((){ user.name=n.text; user.email=e.text; user.phone=p.text; user.address=a.text; user.cards[cardIdx].holder=n.text.toUpperCase(); }); save(); Navigator.pop(context); }, child:const Text("Save", style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold)))), ]))); }
  Widget _edit(TextEditingController c, String l)=> TextField(controller:c, style:const TextStyle(color:Colors.white, fontSize:13), decoration:InputDecoration(labelText:l, labelStyle:const TextStyle(color:Color(0xFFB537F2), fontSize:11), filled:true, fillColor:const Color(0xFF1E1E1E), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none), contentPadding:const EdgeInsets.symmetric(horizontal:12, vertical:12)));
  void _sheet({required bool isAdd}){ String am="0"; showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.transparent, builder:(_)=> StatefulBuilder(builder:(c,setM)=> Container(height:MediaQuery.of(context).size.height*0.7, decoration:const BoxDecoration(color:Color(0xFF111111), borderRadius:BorderRadius.vertical(top:Radius.circular(24))), padding:const EdgeInsets.all(16), child:Column(children:[ Text("\$$am", style:const TextStyle(fontSize:48, fontWeight:FontWeight.w900, color:Colors.white)), Expanded(child:GridView.builder(gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3, childAspectRatio:1.3, crossAxisSpacing:10, mainAxisSpacing:10), itemCount:12, itemBuilder:(c,i){ String lb=["1","2","3","4","5","6","7","8","9",".","0","<"][i]; return InkWell(onTap:(){ setM((){ if(lb=="<"){ if(am.length>1) am=am.substring(0,am.length-1); else am="0"; } else { if(am=="0"&&lb!=".") am=lb; else if(!(lb=="."&&am.contains("."))&&am.length<6) am+=lb; } }); }, child:Container(decoration:BoxDecoration(color:const Color(0xFF1E1E1E), borderRadius:BorderRadius.circular(12)), child:Center(child:Text(lb, style:const TextStyle(fontSize:22, color:Colors.white))))); })), SizedBox(width:double.infinity, height:50, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFB537F2)), onPressed:(){ double m=double.tryParse(am)??0; if(isAdd) user.cards[cardIdx].balance+=m; else user.cards[cardIdx].balance-=m; if(isAdd) user.history.insert(0, {"name":"Cash Added Boston","type":"add","amount":m,"time":"Just now","note":"Boston Office"}); save(); triggerConfetti(); Navigator.pop(context); }, child:Text(isAdd?"Add \$${am}":"Cash Out")))])))); }
  Widget _cardTab()=> Padding(padding:const EdgeInsets.all(20), child:Column(children:[const SizedBox(height:10), SizedBox(height:210, child:Card3DWidget(card:user.cards[cardIdx], onTap:triggerConfetti)), const SizedBox(height:20), Container(padding:const EdgeInsets.all(14), decoration:BoxDecoration(color:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(14)), child:const Row(children:[Icon(Icons.atm, color:Color(0xFFB537F2)), SizedBox(width:10), Text("Tap card for confetti • Boston", style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:11))]))]));

  // PROFILE CON KEEP OPEN
  Widget _bankBoston(){
    return ListView(padding:const EdgeInsets.all(16), children:[
      Row(children:[const CircleAvatar(radius:30, backgroundImage:AssetImage("assets/foto.jpg")), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(user.name, style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:14)), Text(user.email, style:const TextStyle(color:Colors.white70, fontSize:11)), Text("${user.phone} • Boston, MA", style:const TextStyle(color:Color(0xFFB537F2), fontSize:10, fontWeight:FontWeight.bold))])), InkWell(onTap:()=>_editProfile(), child:Container(padding:const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration:BoxDecoration(color:const Color(0xFFB537F2), borderRadius:BorderRadius.circular(16)), child:const Text("Edit", style:TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.bold)))),
      ]),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(14), decoration:BoxDecoration(color:const Color(0xFFB537F2).withOpacity(0.15), borderRadius:BorderRadius.circular(14), border:Border.all(color:const Color(0xFFB537F2).withOpacity(0.3))), child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Row(children:[Icon(user.keepOpen? Icons.fingerprint: Icons.lock_open, size:14, color:const Color(0xFFB537F2)), const SizedBox(width:6), const Text("Keep Open • Fingerprint", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:12))]), const SizedBox(height:2), Text(user.keepOpen? "Pide huella al entrar a la app":"Sesion se cerrará al salir", style:const TextStyle(color:Colors.white60, fontSize:10))]),
        Switch(value:user.keepOpen, activeColor:const Color(0xFFB537F2), onChanged:(v){ setState(()=> user.keepOpen=v); save(); if(!v){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Keep Open OFF: la sesion se cerrara al salir"), backgroundColor:Colors.orange)); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Keep Open ON: pedirá huella al iniciar"), backgroundColor:Color(0xFFB537F2))); } }),
      ])),
      const SizedBox(height:16),
      const Text("BOSTON PROFILE", style:TextStyle(color:Color(0xFFB537F2), fontSize:10, fontWeight:FontWeight.w900)), const SizedBox(height:6),
      _cardInfo([_rowInfo(Icons.person, "Full Name", user.name), _rowInfo(Icons.email, "Email", user.email), _rowInfo(Icons.phone, "Phone", user.phone), _rowInfo(Icons.location_on, "Address", user.address), _rowInfo(Icons.location_city, "City", "${user.city} ${user.zip}"),]),
      const SizedBox(height:14),
      const Text("SECURITY", style:TextStyle(color:Color(0xFFB537F2), fontSize:10, fontWeight:FontWeight.w900)), const SizedBox(height:6),
      _cardInfo([_rowInfo(Icons.fingerprint, "Biometric", user.keepOpen? "Enabled - Fingerprint":"Disabled"), _rowInfo(Icons.security, "FDIC", "Insured up to \$250k"), _rowInfo(Icons.lock, "Session", user.keepOpen? "Keep Open ON":"Will close on exit"),]),
      const SizedBox(height:20),
      SizedBox(width:double.infinity, height:48, child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.red.withOpacity(0.8), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))), onPressed:() async { await Storage.logout(); if(context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(_)=>const AuthCheck()), (r)=> false); }, child:const Text("Log Out • Close Session", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900)))),
      const SizedBox(height:80),
    ]);
  }
  Widget _cardInfo(List<Widget> c)=> Container(decoration:BoxDecoration(color:Colors.white.withOpacity(0.06), borderRadius:BorderRadius.circular(14), border:Border.all(color:Colors.white.withOpacity(0.08))), child:Column(children:c));
  Widget _rowInfo(IconData ic, String k, String v)=> Padding(padding:const EdgeInsets.symmetric(horizontal:12, vertical:10), child:Row(children:[Icon(ic, size:14, color:const Color(0xFFB537F2)), const SizedBox(width:8), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(k, style:const TextStyle(color:Colors.white38, fontSize:9)), Text(v, style:const TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.w600))]))]));
}

class Card3DWidget extends StatefulWidget{ final AppCard card; final VoidCallback? onTap; const Card3DWidget({super.key, required this.card, this.onTap}); @override State<Card3DWidget> createState()=>_Card3DState(); }
class _Card3DState extends State<Card3DWidget> with SingleTickerProviderStateMixin{
  double rx=-0.2, ry=-0.3, mx=0, my=0; bool back=false; late AnimationController c;
  @override void initState(){ super.initState(); c=AnimationController(vsync:this, duration:const Duration(milliseconds:3000))..repeat(reverse:true); }
  @override void dispose(){ c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return GestureDetector(onPanUpdate:(d){ setState((){ my+=d.delta.dx*0.01; mx+=-d.delta.dy*0.01; }); }, onTap:(){ setState(()=> back=!back); if(widget.onTap!=null) widget.onTap!(); }, child: AnimatedBuilder(animation:c, builder:(ctx,_){
        double fy=sin(c.value*3.14159)*6; return Transform(alignment:Alignment.center, transform:Matrix4.identity()..setEntry(3,2,0.001)..translate(0.0,fy,0.0)..rotateX(rx+mx)..rotateY(ry+my), child:TweenAnimationBuilder(tween:Tween<double>(begin:0,end:back?1:0), duration:const Duration(milliseconds:400), builder:(ctx,val,_){ bool isBack=val>0.5; return Transform(alignment:Alignment.center, transform:Matrix4.identity()..setEntry(3,2,0.001)..rotateY(val*3.14159), child:isBack? _backCard(): _frontCard()); })); }),);
  }
  Widget _frontCard(){ return Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(20), gradient:const LinearGradient(colors:[Color(0xFF1A0A2E), Color(0xFFB537F2)]), boxShadow:[BoxShadow(color:const Color(0xFFB537F2).withOpacity(0.7), blurRadius:35, offset:const Offset(0,15))], image:const DecorationImage(image:AssetImage("assets/foto.jpg"), fit:BoxFit.cover, colorFilter:ColorFilter.mode(Colors.black54, BlendMode.darken))), child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Container(width:32, height:22, decoration:BoxDecoration(color:Colors.white.withOpacity(0.9), borderRadius:BorderRadius.circular(3))), const Icon(Icons.contactless_outlined, color:Colors.white70, size:16)]), const Spacer(), const Text("•••• •••• •••• 0371", style:TextStyle(color:Colors.white, fontSize:13, letterSpacing:1.5)), const SizedBox(height:8), Text(widget.card.holder, style:const TextStyle(color:Colors.white, fontSize:9, fontWeight:FontWeight.bold)), const SizedBox(height:2), const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Text("BOSTON • USA", style:TextStyle(color:Colors.white60, fontSize:7)), Text("VISA", style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontStyle:FontStyle.italic, fontSize:14))]),]))); }
  Widget _backCard(){ return Transform(alignment:Alignment.center, transform:Matrix4.identity()..rotateY(3.14159), child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(20), color:const Color(0xFF1A0A2E)), child:Column(children:[const SizedBox(height:14), Container(height:32, color:Colors.black), const SizedBox(height:14), Padding(padding:const EdgeInsets.symmetric(horizontal:12), child:Container(height:26, color:Colors.white, alignment:Alignment.centerRight, padding:const EdgeInsets.only(right:6), child:Text(widget.card.cvv, style:const TextStyle(color:Colors.black, fontSize:10, fontWeight:FontWeight.bold)))), const Spacer(), const Padding(padding:EdgeInsets.only(bottom:8), child:Text("BOSTON MA • VISA", style:TextStyle(color:Color(0xFFB537F2), fontSize:7)))]))); }
}