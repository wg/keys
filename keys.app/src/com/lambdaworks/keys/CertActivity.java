// Copyright (C) 2013 - Will Glozer. All rights reserved.

package com.lambdaworks.keys;

import android.app.Activity;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.*;

import java.io.*;

public class CertActivity extends Activity {
    public void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(R.layout.cert);

        EditText password = (EditText) findViewById(R.id.password);
        password.setKeyListener(null);
        password.setText(getIntent().getStringExtra("password"));

        TextView cert = (TextView) findViewById(R.id.cert);
        cert.setKeyListener(null);

        StringWriter str = new StringWriter();
        try {
            writeCert(str);
            cert.setText(str.toString());
        } catch (Exception e) {
            Log.e("keys", "Unable to read cert", e);
        }
    }

    public void done(View v) {
        finish();
    }

    public void copyCert(View v) {
        File dst = new File(Environment.getExternalStorageDirectory(), "client.pem");
        try {
            writeCert(new FileWriter(dst));
            String msg = getResources().getString(R.string.certCopied, dst.getPath());
            Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
        } catch (IOException e) {
            Log.e("keys", "Unable to copy cert", e);
        }
    }

    private void writeCert(Writer dst) throws IOException {
        File cert = new File(KeysCore.databaseDir(getApplicationContext()), "client.pem");
        Reader src = new InputStreamReader(new FileInputStream(cert), "ASCII");
        try {
            char[] buf = new char[2048];
            int len;
            while ((len = src.read(buf)) != -1) {
                dst.write(buf, 0, len);
            }
        } finally {
            src.close();
            dst.close();
        }
    }
}