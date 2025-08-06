import 'package:flutter/material.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_constants.dart';
import 'package:sip_sdk_flutter_example/sip_manage.dart';

import 'call_page.dart';
import 'config_storage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int? statusCode; // 当前状态码

  final TextEditingController domainController =
      TextEditingController(text: "test.com");
  final TextEditingController usernameController =
      TextEditingController(text: "test");
  final TextEditingController passwordController =
      TextEditingController(text: "123456");
  final TextEditingController serverAddrController =
      TextEditingController(text: "43.160.204.96");
  final TextEditingController serverPortController =
      TextEditingController(text: "5060");
  final TextEditingController proxyController =
      TextEditingController(text: "43.160.204.96");
  final TextEditingController proxyPortController =
      TextEditingController(text: "5060");
  final TextEditingController callUsernameController =
      TextEditingController(text: "test1");

  bool stunEnable = true;
  bool stunEnableIPv6 = false;
  final TextEditingController stunServerController =
      TextEditingController(text: "120.79.7.237:3478");

  bool turnEnable = true;
  final TextEditingController turnServerController =
      TextEditingController(text: "120.79.7.237:3478");
  final TextEditingController turnRealmController =
      TextEditingController(text: "120.79.7.237");
  final TextEditingController turnUsernameController =
      TextEditingController(text: "test");
  final TextEditingController turnPasswordController =
      TextEditingController(text: "test");

  // SIP注册回调
  SIPListener? sipListener;

  @override
  void initState() {
    super.initState();
    sipListener = SIPListener(onRegistrarState: (int state) {
      setState(() {
        statusCode = state;
      });
    });
    SIPManage().addListener(sipListener!);

    _init();
  }

  Future<void> _init() async {
    ConfigStorage.load(ConfigStorage.sip_config).then((sipConfig) {
      Map<String, dynamic> config;
      if (sipConfig == null) {
        //写入默认值
        config = {
          "domain": domainController.text,
          "username": usernameController.text,
          "password": passwordController.text,
          "serverAddr": serverAddrController.text,
          "serverPort": int.tryParse(serverPortController.text) ?? 5060,
          "proxy": proxyController.text,
          "proxyPort": int.tryParse(proxyPortController.text) ?? 5060,
          "callUsername": callUsernameController.text,
        };
        ConfigStorage.save(ConfigStorage.sip_config, config);
      } else {
        config = sipConfig;
      }
      setState(() {
        domainController.text = config["domain"];
        usernameController.text = config["username"];
        passwordController.text = config["password"];
        serverAddrController.text = config["serverAddr"];
        serverPortController.text = config["serverPort"].toString();
        proxyController.text = config["proxy"];
        proxyPortController.text = config["proxyPort"].toString();
        callUsernameController.text = config["callUsername"].toString();
      });
    });
    ConfigStorage.load(ConfigStorage.stun_config).then((stunConfig) {
      Map<String, dynamic> config;
      if (stunConfig == null) {
        //写入默认值
        config = {
          "enable": stunEnable,
          "enableIPv6": stunEnableIPv6,
          "server": stunServerController.text,
        };
        ConfigStorage.save(ConfigStorage.stun_config, config);
      } else {
        config = stunConfig;
      }
      setState(() {
        stunEnable = config["enable"];
        stunEnableIPv6 = config["enableIPv6"];
        stunServerController.text = config["server"];
      });
    });

    ConfigStorage.load(ConfigStorage.turn_config).then((turnConfig) {
      Map<String, dynamic> config;
      if (turnConfig == null) {
        //写入默认值
        config = {
          "enable": turnEnable,
          "server": turnServerController.text,
          "realm": turnRealmController.text,
          "username": turnUsernameController.text,
          "password": turnPasswordController.text
        };
        ConfigStorage.save(ConfigStorage.turn_config, config);
      } else {
        config = turnConfig;
      }
      setState(() {
        turnEnable = config["enable"];
        turnServerController.text = config["server"];
        turnRealmController.text = config["realm"];
        turnUsernameController.text = config["username"];
        turnPasswordController.text = config["password"];
      });
    });
    //初始化SIP
    SIPManage.initialize();
  }

  void registrar() {
    final config = {
      "domain": domainController.text,
      "username": usernameController.text,
      "password": passwordController.text,
      "serverAddr": serverAddrController.text,
      "serverPort": int.tryParse(serverPortController.text) ?? 5060,
      "proxy": proxyController.text,
      "proxyPort": int.tryParse(proxyPortController.text) ?? 5060,
      "callUsername": callUsernameController.text,
    };
    // 保存配置
    ConfigStorage.save(ConfigStorage.sip_config, config);
    // 这里调用 SIP SDK 注册方法
    SIPManage.registrar();
  }

  void call() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) {
        int direction = 0; //0.主动呼叫 1.被叫
        return CallPage(
            direction: direction,
            callType: SIPSDKConstants.SDK_CALL_TYPE_SERVER,
            username: callUsernameController.text,
            headers: const {
              "test": "test",
            });
      }),
    );
  }

  void saveStun() {
    final config = {
      "enable": stunEnable,
      "enableIPv6": stunEnableIPv6,
      "server": stunServerController.text,
    };
    // 保存配置
    ConfigStorage.save(ConfigStorage.stun_config, config);
  }

  void saveTurn() {
    final config = {
      "enable": turnEnable,
      "server": turnServerController.text,
      "realm": turnRealmController.text,
      "username": turnUsernameController.text,
      "password": turnPasswordController.text
    };
    // 保存配置
    ConfigStorage.save(ConfigStorage.turn_config, config);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        autofocus: false,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildLabeledSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget sipWidget() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          _buildTextField("Domain", domainController),
          _buildTextField("Username", usernameController),
          _buildTextField("Password", passwordController),
          _buildTextField("Server Addr", serverAddrController),
          _buildTextField("Server Port", serverPortController,
              keyboardType: TextInputType.number),
          _buildTextField("Proxy", proxyController),
          _buildTextField("Proxy Port", proxyPortController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: registrar,
            child: const Text("registrar"),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField("Call Username", callUsernameController),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: call,
                child: const Text("call"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget stunWidget() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          _buildLabeledSwitch("enable", stunEnable, (newVal) {
            setState(() {
              stunEnable = newVal;
            });
          }),
          _buildLabeledSwitch("enable ipv6", stunEnableIPv6, (newVal) {
            setState(() {
              stunEnableIPv6 = newVal;
            });
          }),
          _buildTextField("server", stunServerController),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: saveStun,
            child: const Text("save"),
          ),
        ],
      ),
    );
  }

  Widget turnWidget() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          _buildLabeledSwitch("enable", turnEnable, (newVal) {
            setState(() {
              turnEnable = newVal;
            });
          }),
          _buildTextField("server", turnServerController),
          _buildTextField("realm", turnRealmController),
          _buildTextField("username", turnUsernameController),
          _buildTextField("password", turnPasswordController),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: saveTurn,
            child: const Text("save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;
    if (statusCode == null) {
      titleWidget = const Text("SIP 配置");
    } else if (statusCode == 200) {
      titleWidget = const Text(
        "Registration Status: 200 ok",
        style: TextStyle(color: Colors.green),
      );
    } else {
      titleWidget = Text(
        "Registration Status: $statusCode",
        style: const TextStyle(color: Colors.red),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: titleWidget,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'SIP'),
              Tab(text: 'STUN'),
              Tab(text: 'TURN'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            sipWidget(),
            stunWidget(),
            turnWidget(),
          ],
        ),
      ),
    );
  }
}
