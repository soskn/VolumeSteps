/*
 * Volume Steps - fabricated-overlay unregister helper
 * Volume Steps - 叠加层注销辅助程序
 *
 * EN: Removes root-fabricated RRO overlays from the OverlayManager service.
 *     There is no shell command to delete a fabricated overlay, so this tiny
 *     helper calls IOverlayManager.commit() with an
 *     OverlayManagerTransaction.unregisterFabricatedOverlay() request.
 *     It uses pure reflection so it does NOT need any hidden framework
 *     classes at compile time and can be compiled with a plain JDK.
 *
 * CN: 从 OverlayManager 服务中删除由 root fabricate 出来的 RRO 叠加层。
 *     Shell 没有提供删除已 fabricate 叠加层的命令，因此用这个小程序，
 *     通过 IOverlayManager.commit() 提交一个
 *     OverlayManagerTransaction.unregisterFabricatedOverlay() 请求。
 *     全程使用反射，编译时无需任何隐藏 framework 类，普通 JDK 即可编译。
 *
 * Usage / 用法:
 *   CLASSPATH=unregister.dex app_process /system/bin RmOv pkg:name [pkg:name ...]
 *   e.g. / 例如: RmOv com.android.shell:volsteps_ring
 *
 * Build / 编译: see tools/build-dex.sh  (需 d8 + JDK)
 */
public class RmOv {
    public static void main(String[] args) throws Exception {
        // EN: Binder handle of the "overlay" system service.
        // CN: "overlay" 系统服务的 Binder 句柄。
        Object binder = Class.forName("android.os.ServiceManager")
                .getMethod("getService", String.class).invoke(null, "overlay");

        // EN: Wrap it with the hidden IOverlayManager AIDL interface.
        // CN: 用隐藏的 IOverlayManager AIDL 接口包装。
        Class<?> ibinder = Class.forName("android.os.IBinder");
        Object om = Class.forName("android.content.om.IOverlayManager$Stub")
                .getMethod("asInterface", ibinder).invoke(null, binder);

        Class<?> oidC = Class.forName("android.content.om.OverlayIdentifier");
        Class<?> txnC = Class.forName("android.content.om.OverlayManagerTransaction");
        Class<?> builderC = Class.forName("android.content.om.OverlayManagerTransaction$Builder");
        Class<?> iomC = Class.forName("android.content.om.IOverlayManager");

        for (String id : args) {
            int c = id.indexOf(':');
            // EN: OverlayIdentifier("<package>", "<name>").
            // CN: OverlayIdentifier("<包名>", "<名称>")。
            Object oid = oidC.getConstructor(String.class, String.class)
                    .newInstance(id.substring(0, c), id.substring(c + 1));

            // EN: Build a transaction and commit it.
            // CN: 构建事务并提交。
            Object builder = builderC.getDeclaredConstructor().newInstance();
            builderC.getMethod("unregisterFabricatedOverlay", oidC).invoke(builder, oid);
            Object txn = builderC.getMethod("build").invoke(builder);
            iomC.getMethod("commit", txnC).invoke(om, txn);

            System.out.println("unregistered " + id);
        }
    }
}
