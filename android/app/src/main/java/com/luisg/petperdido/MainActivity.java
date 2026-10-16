package com.luisg.petperdido;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {

    /** Mesmo id usado no AndroidManifest (default_notification_channel_id). */
    private static final String CANAL_ALERTAS = "alertas_pets";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        criarCanalDeAlertas();
    }

    /** Canal das notificações de pets por perto (Android 8+), com prioridade alta. */
    private void criarCanalDeAlertas() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationChannel canal = new NotificationChannel(
                CANAL_ALERTAS,
                "Alertas de pets por perto",
                NotificationManager.IMPORTANCE_HIGH);
        canal.setDescription("Avisos de pets perdidos, encontrados ou avistados perto de você.");
        NotificationManager gerenciador = getSystemService(NotificationManager.class);
        if (gerenciador != null) gerenciador.createNotificationChannel(canal);
    }
}
