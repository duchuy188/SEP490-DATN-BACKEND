/**
 * @swagger
 * components:
 *   schemas:
 *     UserProfile:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           example: "123e4567-e89b-12d3-a456-426614174000"
 *         email:
 *           type: string
 *           format: email
 *           example: "user@example.com"
 *         full_name:
 *           type: string
 *           example: "Nguyen Van A"
 *         phone:
 *           type: string
 *           example: "0123456789"
 *         date_of_birth:
 *           type: string
 *           format: date
 *           example: "1990-01-01"
 *         role:
 *           type: string
 *           enum: [admin, pilgrim, local_guide]
 *           example: "pilgrim"
 *         status:
 *           type: string
 *           enum: [active, banned]
 *           example: "active"
 *         created_at:
 *           type: string
 *           format: date-time
 *           example: "2024-01-01T00:00:00.000Z"
 *         updated_at:
 *           type: string
 *           format: date-time
 *           example: "2024-01-01T00:00:00.000Z"
 *
 *     UserListResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           example: true
 *         message:
 *           type: string
 *           example: "Get users successfully"
 *         data:
 *           type: object
 *           properties:
 *             users:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/UserProfile'
 *             pagination:
 *               type: object
 *               properties:
 *                 total:
 *                   type: integer
 *                   example: 100
 *                 page:
 *                   type: integer
 *                   example: 1
 *                 limit:
 *                   type: integer
 *                   example: 10
 *                 totalPages:
 *                   type: integer
 *                   example: 10
 *
 *     UpdateUserStatusRequest:
 *       type: object
 *       required:
 *         - status
 *       properties:
 *         status:
 *           type: string
 *           enum: [active, banned]
 *           example: "banned"
 *           description: "active = unblock user, banned = block user"
 *
 *     UpdateUserRequest:
 *       type: object
 *       properties:
 *         full_name:
 *           type: string
 *           example: "Nguyen Van B"
 *           description: "Họ tên mới"
 *         phone:
 *           type: string
 *           example: "0987654321"
 *           description: "Số điện thoại mới"
 *         date_of_birth:
 *           type: string
 *           format: date
 *           example: "1995-05-15"
 *           description: "Ngày sinh mới"
 *         role:
 *           type: string
 *           enum: [pilgrim, local_guide]
 *           example: "local_guide"
 *           description: "Role mới (không thể đổi thành admin)"
 *
 *     UserUpdateResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           example: true
 *         message:
 *           type: string
 *           example: "User information updated successfully"
 *         data:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *               format: uuid
 *             email:
 *               type: string
 *             full_name:
 *               type: string
 *             phone:
 *               type: string
 *             date_of_birth:
 *               type: string
 *               format: date
 *             role:
 *               type: string
 *             status:
 *               type: string
 */

module.exports = {};
