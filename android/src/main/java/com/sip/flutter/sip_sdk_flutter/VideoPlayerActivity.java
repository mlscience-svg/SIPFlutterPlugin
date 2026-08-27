package com.sip.flutter.sip_sdk_flutter;

import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.VideoView;

import java.util.Locale;

/**
 * 全屏视频播放页：门铃 AVI 走系统 MediaPlayer（VideoView）。
 *
 * 用独立 Activity 而非 Dialog —— Dialog 在部分 ROM（ColorOS）上盖不满全屏，
 * 会把背后 App 的界面（顶栏）顶上去；Activity 完整覆盖应用，不会动到背后 UI。
 * 沉浸式隐藏系统栏；底部自定义控制栏（播放/暂停 + 可拖动进度条 + 时间）。
 * 不强制旋转：视频按原始比例居中（横屏视频在竖屏里是居中横带），用户可自行
 * 横屏手机观看。
 */
public class VideoPlayerActivity extends Activity {
    private VideoView videoView;
    private final boolean[] userSeeking = {false}; // 手指按住拖动时不回写进度
    private final long[] stopped = {0L};           // onDestroy 后停止轮询
    private final boolean[] playing = {true};

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setBackgroundDrawable(null);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        final float density = getResources().getDisplayMetrics().density;
        FrameLayout frame = new FrameLayout(this);
        frame.setBackgroundColor(Color.BLACK);

        videoView = new VideoView(this);
        FrameLayout.LayoutParams videoLp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
        // VideoView 会按视频宽高比把自己量成"贴宽"小块（横屏视频在竖屏里是横带），
        // 不加 gravity 会放到左上角被顶到状态栏下；居中放置。
        videoLp.gravity = Gravity.CENTER;
        frame.addView(videoView, videoLp);

        // 加载中转圈
        ProgressBar loading = new ProgressBar(this);
        frame.addView(loading, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER));

        // 右上角关闭
        TextView close = new TextView(this);
        close.setText("✕");
        close.setTextSize(26);
        close.setTextColor(Color.WHITE);
        close.setGravity(Gravity.CENTER);
        FrameLayout.LayoutParams closeLp =
                new FrameLayout.LayoutParams(72, 72, Gravity.TOP | Gravity.END);
        closeLp.topMargin = 48;
        closeLp.rightMargin = 20;
        close.setOnClickListener(v -> finish());
        frame.addView(close, closeLp);

        // 底部控制栏：播放/暂停 + 进度条 + 当前/总时长
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setBackgroundColor(0x99000000);
        int pad = (int) (10 * density);
        bar.setPadding(pad, pad, pad, pad);

        TextView playPause = new TextView(this);
        playPause.setText("⏸");
        playPause.setTextSize(20);
        playPause.setTextColor(Color.WHITE);
        playPause.setGravity(Gravity.CENTER);
        bar.addView(playPause, new LinearLayout.LayoutParams(
                (int) (44 * density), (int) (44 * density)));

        TextView current = new TextView(this);
        current.setText("00:00");
        current.setTextSize(13);
        current.setTextColor(Color.WHITE);
        bar.addView(current, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        SeekBar seek = new SeekBar(this);
        seek.setMax(0);
        seek.setPadding((int) (6 * density), 0, (int) (6 * density), 0);
        bar.addView(seek, new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        TextView total = new TextView(this);
        total.setText("00:00");
        total.setTextSize(13);
        total.setTextColor(Color.WHITE);
        bar.addView(total, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        FrameLayout.LayoutParams barLp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM);
        barLp.setMargins(0, 0, 0, (int) (8 * density));
        frame.addView(bar, barLp);

        // 轮询更新进度（Handler 轮询 MediaPlayer 位置，驱动 SeekBar 与时间）
        Runnable poll = new Runnable() {
            @Override
            public void run() {
                if (stopped[0] == 1L) return;
                try {
                    if (videoView.isPlaying()) {
                        int dur = videoView.getDuration();
                        seek.setMax(Math.max(dur, 0));
                        if (!userSeeking[0]) {
                            seek.setProgress(videoView.getCurrentPosition());
                        }
                        current.setText(fmtTime(videoView.getCurrentPosition()));
                        total.setText(fmtTime(dur));
                    }
                } catch (Exception ignored) {
                }
                videoView.postDelayed(this, 250);
            }
        };

        seek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar sb, int progress, boolean fromUser) {
                if (fromUser) current.setText(fmtTime(progress));
            }

            @Override
            public void onStartTrackingTouch(SeekBar sb) {
                userSeeking[0] = true;
            }

            @Override
            public void onStopTrackingTouch(SeekBar sb) {
                userSeeking[0] = false;
                try {
                    videoView.seekTo(sb.getProgress());
                } catch (Exception ignored) {
                }
            }
        });

        playPause.setOnClickListener(v -> {
            playing[0] = !playing[0];
            try {
                if (playing[0]) {
                    videoView.start();
                    playPause.setText("⏸");
                } else {
                    videoView.pause();
                    playPause.setText("▶");
                }
            } catch (Exception ignored) {
            }
        });

        // 点视频区域切换控制栏显隐
        videoView.setOnClickListener(v -> bar.setVisibility(
                bar.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE));

        videoView.setOnPreparedListener(mp -> {
            loading.setVisibility(View.GONE);
            int dur = Math.max(mp.getDuration(), 0);
            seek.setMax(dur);
            total.setText(fmtTime(dur));
            videoView.start();
            videoView.post(poll);
        });
        videoView.setOnErrorListener((mp, what, extra) -> {
            loading.setVisibility(View.GONE);
            finish();
            return true;
        });
        videoView.setOnCompletionListener(mp -> finish());

        setContentView(frame);
        hideSystemBars();

        String uriStr = getIntent().getStringExtra("uri");
        if (uriStr != null && !uriStr.isEmpty()) {
            videoView.setVideoURI(Uri.parse(uriStr));
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        // 每次窗口获焦后重新隐藏系统栏（避免被系统栏/手势提示重新弹出顶开布局）
        if (hasFocus) hideSystemBars();
    }

    private void hideSystemBars() {
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    }

    @Override
    protected void onDestroy() {
        stopped[0] = 1L;
        try {
            videoView.stopPlayback();
        } catch (Exception ignored) {
        }
        super.onDestroy();
    }

    /** 毫秒 -> mm:ss。 */
    private static String fmtTime(int ms) {
        int s = Math.max(ms, 0) / 1000;
        return String.format(Locale.US, "%02d:%02d", s / 60, s % 60);
    }
}
