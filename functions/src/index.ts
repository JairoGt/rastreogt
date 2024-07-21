import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Inicializar Firebase Admin SDK
admin.initializeApp();

// Función para notificar cuando se crea un nuevo pedido
exports.notifyOnNewPedido = functions.firestore
  .document("pedidos/{pedidoId}/Productos/{productoId}")
  .onCreate(async (snap, context) => {
    const pedidoId = context.params.pedidoId;

    // Obtener la referencia a la subcolección 'Productos'
    const productosSnapshot = await admin.firestore()
      .collection(`pedidos/${pedidoId}/Productos`).get();

    const tokens: string[] = [];
    productosSnapshot.forEach((productoDoc) => {
      const token = productoDoc.data().token;
      if (token) {
        tokens.push(token);
      }
    });

    if (tokens.length > 0) {
      const message = {
        tokens: tokens,
        notification: {
          title: "Nuevo Pedido",
          body: "¡Tu pedido ha sido creado!",
        },
      };

      try {
        const response = await admin.messaging().sendMulticast(message);
        console.log("Notificaciones enviadas exitosamente:", response);
      } catch (error) {
        console.error("Error al enviar las notificaciones:", error);
      }
    } else {
      console.log("No hay tokens para enviar notificaciones.");
    }

    return null;
  });

// Función para notificar cuando se actualiza un pedido

// Mapeo de los IDs de estado a sus nombres
const estados: { [key: number]: string } = {
  1: "Pendiente",
  2: "En proceso",
  3: "En camino",
  4: "Entregado",
  // Agrega aquí los demás estados según necesites
};
exports.notificarCambioEstado = functions.firestore
  .document("pedidos/{idpedidos}")
  .onUpdate(async (change, context) => {
    const pedidoAnterior = change.before.data();
    const pedidoActual = change.after.data();


    // Verificar si el estado del pedido ha cambiado
    if (pedidoAnterior.estadoid !== pedidoActual.estadoid) {
      // Obtener el ID del pedido y el nuevo estado

      const pedidoId = context.params.idpedidos;
      const nuevoEstadoId = pedidoActual.estadoid;
      const nuevoEstadoNombre = estados[nuevoEstadoId];

      // Crear la notificación
      const mensaje = {
        notification: {
          title: `El estado de tu pedido ${pedidoId} ha cambiado`,
          body: `Tu pedido ha sido marcado como ${nuevoEstadoNombre}`,
        },
        topic: `pedido_${pedidoId}`,
      };

      // Enviar la notificación
      try {
        await admin.messaging().send(mensaje);
      } catch (error) {
        console.error("Error al enviar la notificación:", error);
      }
    }
    return null;
  });
