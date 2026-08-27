import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_complete_param.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_constants.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_offer_param.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_param.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_progress.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_request_info.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_ft_request_param.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_message.dart';
import 'package:sip_sdk_flutter_example/sip_manage.dart';

/// 文件传输（FT）演示页，交互与 Android 侧 FileTransferActivity 保持一致。
///
/// 发送：填写对端账号（Username）或 IP，选择（或创建）本地文件，点击"发送文件"。
/// 接收：收到对端 offer 时弹窗选择接收或拒绝；收到对端请求文件时弹窗选择本地文件发送或拒绝。
class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController();
  final TextEditingController _fileNameController =
      TextEditingController(text: "test.txt");

  SIPListener? _sipListener;
  String _log = "";
  int _currentFtId = 0;
  // 本地保存/测试文件目录（无需额外依赖即可写入的绝对路径）
  late Directory _ftDir;

  @override
  void initState() {
    super.initState();
    _ftDir = Directory('${Directory.systemTemp.path}/sip_ft');
    _ftDir.createSync(recursive: true);
    _log = "FT 演示已就绪，保存目录: ${_ftDir.path}";
    _sipListener = SIPListener(
      onFTOffer: _onOffer,
      onFTRequest: _onRequest,
      onFTRequestResult: _onRequestResult,
      onFTProgress: _onProgress,
      onFTComplete: _onComplete,
      onMessageState: _onMessageState,
    );
    SIPManage().addListener(_sipListener!);
  }

  @override
  void dispose() {
    SIPManage().removeListener(_sipListener!);
    super.dispose();
  }

  // ---- 接收 / 请求弹窗 ----

  void _onOffer(SIPSDKFTOfferParam param) {
    _currentFtId = param.ftId;
    final String fileName = param.file.name;
    _appendLog("收到文件传输请求: $fileName (${param.file.size} 字节)，发送方=${param.username}");
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("接收文件"),
        content: Text("对端 ${param.username} (${param.remoteIp})\n"
            "文件: $fileName\n大小: ${param.file.size} 字节\n\n是否接收？"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final savePath = "${_ftDir.path}/$fileName";
              final ret = await SIPManage().acceptFile(param.ftId, savePath);
              _appendLog("acceptFile ftId=${param.ftId} ret=$ret 保存到 $savePath");
            },
            child: const Text("接收"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ret = await SIPManage().rejectFile(param.ftId, "user reject");
              _appendLog("rejectFile ftId=${param.ftId} ret=$ret");
            },
            child: const Text("拒绝"),
          ),
        ],
      ),
    );
  }

  void _onRequest(SIPSDKFTRequestInfo info) {
    final String reqName = info.file.name;
    _appendLog("收到文件请求: 对方要文件=$reqName，请求方=${info.username} (${info.remoteIp})");
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("对方请求文件"),
        content: Text("对端 ${info.username} (${info.remoteIp})\n"
            "请求文件: $reqName\n\n是否从本地发送该文件？"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickPathForRespond(info.reqId);
            },
            child: const Text("选择并发送"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ret = await SIPManage().respondRequest(info.reqId, false, "");
              _appendLog("已拒绝请求 reqId=${info.reqId} ret=$ret");
            },
            child: const Text("拒绝"),
          ),
        ],
      ),
    );
  }

  // 回应对方文件请求：弹出路径输入框，确认后 respondRequest 同意
  Future<void> _pickPathForRespond(int reqId) async {
    final controller = TextEditingController(text: _filePathController.text);
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("选择要发送的文件"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "文件绝对路径",
            hintText: '可先点"测试文件"生成',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text("发送"),
          ),
        ],
      ),
    );
    if (path == null || path.isEmpty) return;
    _filePathController.text = path;
    final ret = await SIPManage().respondRequest(reqId, true, path);
    _appendLog("respondRequest reqId=$reqId accept=1 ret=$ret 文件=$path");
  }

  // ---- 请求结果 / 信令失败反馈 ----

  void _onRequestResult(int reqId, bool ok, String reason) {
    String tail;
    if (ok) {
      tail = " 对端同意，等待对方发送…";
    } else if (reason.startsWith("信令失败")) {
      // 信令错误：对端根本没收到请求，不算"拒绝"
      tail = " 请求失败：$reason";
    } else {
      tail = " 对端拒绝${reason.isNotEmpty ? "：$reason" : ""}";
    }
    _appendLog("请求结果 reqId=$reqId$tail");
  }

  // 我发起的请求 MESSAGE 信令失败（如 408）时的反馈：对端根本没收到请求，
  // onRequestResult 不会触发，这里把信令失败同样报告成"请求文件失败"
  void _onMessageState(int state, SIPSDKMessage message) {
    if (state < 300 || message.content.isEmpty) return;
    // 只关心我们发出去的"请求文件"信令（t=request）
    if (!message.content.contains('"t":"request"')) return;
    final reqId = _parseReqId(message.content);
    if (reqId > 0) {
      _onRequestResult(reqId, false, "信令失败($state)，消息未送达对方");
    }
  }

  // 从 FT 信令 JSON 里解析 reqId（"id":"<16位hex>"，例如 "id":"000680b9f09e6001"）
  int _parseReqId(String content) {
    const marker = '"id":"';
    final start = content.indexOf(marker);
    if (start < 0) return -1;
    final idStart = start + marker.length;
    final end = content.indexOf('"', idStart);
    if (end <= idStart) return -1;
    return int.tryParse(content.substring(idStart, end), radix: 16) ?? -1;
  }

  // ---- 进度 / 完成（每个文件一条，就地更新） ----

  void _onProgress(SIPSDKFTProgress progress) {
    _updateFileLine(
      progress.ftId,
      "${progress.percent}% (${progress.bytesDone}/${progress.bytesTotal}) "
          "${_stateName(progress.state)}",
    );
  }

  void _onComplete(SIPSDKFTCompleteParam param) {
    final extra = param.role == SIPSDKFTConstants.ftRoleReceiver &&
            param.savePath.isNotEmpty
        ? " 保存到=${param.savePath}"
        : "";
    _updateFileLine(
      param.ftId,
      "${_errorName(param.error)} 文件=${param.fileName} "
          "字节=${param.bytesTransferred} 耗时=${param.elapsedMs}ms$extra",
    );
  }

  // ---- 按钮动作 ----

  Future<void> _createTestFile() async {
    final file = File(
        '${_ftDir.path}/sip_ft_test_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString('文件传输测试内容\n' * 200);
    _filePathController.text = file.path;
    _appendLog("已创建测试文件: ${file.path} (${await file.length()} 字节)");
  }

  Future<void> _sendFile() async {
    final target = _targetController.text.trim();
    final filePath = _filePathController.text.trim();
    if (target.isEmpty) {
      _toast("请输入对端账号或 IP");
      return;
    }
    if (filePath.isEmpty) {
      _toast("请先选择要发送的文件");
      return;
    }
    final param = SIPSDKFTParam(
      accUuid: 0,
      username: _isIP(target) ? '' : target,
      remoteIp: _isIP(target) ? target : '',
      filePath: filePath,
    );
    final result = await SIPManage().sendFile(param);
    if (result.success) {
      _currentFtId = result.ftId;
      _appendLog("发送请求已提交，ftId=$_currentFtId，文件=$filePath");
    } else {
      _appendLog("发送失败，错误码=${result.code}");
    }
  }

  Future<void> _requestFile() async {
    final target = _targetController.text.trim();
    final fileName = _fileNameController.text.trim();
    if (target.isEmpty) {
      _toast("请输入对端账号或 IP");
      return;
    }
    if (fileName.isEmpty) {
      _toast("请输入要请求的文件名");
      return;
    }
    final param = SIPSDKFTRequestParam(
      accUuid: 0,
      username: _isIP(target) ? '' : target,
      remoteIp: _isIP(target) ? target : '',
      fileName: fileName,
    );
    final result = await SIPManage().requestFile(param);
    if (result.success) {
      _appendLog("请求文件已提交，reqId=${result.reqId}，请求=$fileName，目标=$target");
    } else {
      _appendLog("请求文件失败，错误码=${result.code}");
    }
  }

  Future<void> _cancel() async {
    if (_currentFtId == 0) {
      _toast("当前没有传输会话");
      return;
    }
    final ret = await SIPManage().cancelFile(_currentFtId);
    _appendLog("已发送取消指令 ftId=$_currentFtId ret=$ret");
  }

  Future<void> _showState() async {
    if (_currentFtId == 0) {
      _toast("当前没有传输会话");
      return;
    }
    final state = await SIPManage().getFileState(_currentFtId);
    final stateText = state >= 0 ? _stateName(state) : "错误码 $state";
    _appendLog("查询状态 ftId=$_currentFtId state=$stateText");
  }

  // ---- 工具 ----

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _appendLog(String msg) {
    final newLog = msg + (_log.isNotEmpty ? "\n$_log" : "");
    _log = _trimLog(newLog);
    if (mounted) setState(() {});
  }

  // 以 [FT<ftId>] 为标记：已存在则就地替换该行，否则插到最上面
  void _updateFileLine(int ftId, String content) {
    final tag = "[FT$ftId]";
    final sb = StringBuffer();
    var found = false;
    for (final line in _log.split("\n")) {
      if (line.isEmpty) continue;
      if (!found && line.startsWith(tag)) {
        sb.writeln("$tag $content");
        found = true;
      } else {
        sb.writeln(line);
      }
    }
    var text = sb.toString();
    if (text.endsWith("\n")) {
      text = text.substring(0, text.length - 1);
    }
    if (!found) {
      text = "$tag $content${text.isNotEmpty ? "\n$text" : ""}";
    }
    _log = _trimLog(text);
    if (mounted) setState(() {});
  }

  // 超长截断：保留最新（最上面）的部分，按整行截
  String _trimLog(String text) {
    if (text.length <= 8000) return text;
    final end = text.indexOf('\n', 6000);
    return end > 0 ? text.substring(0, end) : text.substring(0, 6000);
  }

  bool _isIP(String value) {
    if (value.isEmpty) return false;
    return RegExp(
      r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}'
      r'(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$',
    ).hasMatch(value);
  }

  String _stateName(int state) {
    switch (state) {
      case SIPSDKFTConstants.ftStateNegotiating:
        return "协商中";
      case SIPSDKFTConstants.ftStateIceConnecting:
        return "ICE建连";
      case SIPSDKFTConstants.ftStateTransferring:
        return "传输中";
      case SIPSDKFTConstants.ftStateComplete:
        return "完成";
      case SIPSDKFTConstants.ftStateError:
        return "出错";
      case SIPSDKFTConstants.ftStateCancelled:
        return "已取消";
      default:
        return "未知($state)";
    }
  }

  String _errorName(int error) {
    switch (error) {
      case SIPSDKFTConstants.ftErrNone:
        return "传输完成";
      case SIPSDKFTConstants.ftErrBusy:
        return "失败：无空闲会话槽";
      case SIPSDKFTConstants.ftErrOpenFile:
        return "失败：打开文件失败";
      case SIPSDKFTConstants.ftErrIce:
        return "失败：ICE 建连失败";
      case SIPSDKFTConstants.ftErrTimeout:
        return "失败：超时";
      case SIPSDKFTConstants.ftErrPeerCancel:
        return "失败：对端取消";
      case SIPSDKFTConstants.ftErrLocalCancel:
        return "失败：本端取消";
      case SIPSDKFTConstants.ftErrProtocol:
        return "失败：协议错误";
      case SIPSDKFTConstants.ftErrRejected:
        return "失败：对端拒绝";
      default:
        return "失败：错误码 $error";
    }
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("文件传输 (FT)")),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildField("对端账号或 IP", _targetController),
                Row(
                  children: [
                    Expanded(child: _buildField("文件路径", _filePathController)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _createTestFile,
                      child: const Text("测试文件"),
                    ),
                  ],
                ),
                _buildField("请求的文件名", _fileNameController),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sendFile,
                        child: const Text("发送文件"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _requestFile,
                        child: const Text("请求文件"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancel,
                        child: const Text("取消"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showState,
                        child: const Text("查询状态"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: SelectableText(
                  _log.isEmpty ? "(暂无日志)" : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
