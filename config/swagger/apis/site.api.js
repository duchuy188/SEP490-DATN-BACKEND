/**
 * @swagger
 * tags:
 *   name: Sites
 *   description: API quản lý địa điểm hành hương
 */

/**
 * @swagger
 * /api/admin/sites:
 *   post:
 *     summary: Tạo địa điểm mới (Admin only)
 *     tags: [Sites]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - region
 *               - type
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Nhà thờ Đức Bà Sài Gòn"
 *                 description: "Tên địa điểm (2-255 ký tự)"
 *               description:
 *                 type: string
 *                 example: "Nhà thờ chính tòa của Tổng Giáo phận Sài Gòn"
 *               history:
 *                 type: string
 *                 example: "Được xây dựng từ năm 1863-1880..."
 *               address:
 *                 type: string
 *                 example: "01 Công xã Paris, Bến Nghé, Quận 1"
 *               province:
 *                 type: string
 *                 example: "Hồ Chí Minh"
 *               district:
 *                 type: string
 *                 example: "Quận 1"
 *               latitude:
 *                 type: number
 *                 format: float
 *                 example: 10.779738
 *                 description: "Vĩ độ (-90 đến 90)"
 *               longitude:
 *                 type: number
 *                 format: float
 *                 example: 106.699092
 *                 description: "Kinh độ (-180 đến 180)"
 *               region:
 *                 type: string
 *                 enum:
 *                   - Bac
 *                   - Trung
 *                   - Nam
 *                 example: "Nam"
 *                 description: "Vùng miền"
 *               type:
 *                 type: string
 *                 enum:
 *                   - church
 *                   - shrine
 *                   - monastery
 *                   - center
 *                   - other
 *                 example: "church"
 *                 description: "Loại địa điểm"
 *               patron_saint:
 *                 type: string
 *                 example: "Đức Mẹ Vô Nhiễm Nguyên Tội"
 *                 description: "Thánh bổn mạng"
 *               opening_hours:
 *                 type: object
 *                 example:
 *                   monday: "05:00-18:00"
 *                   tuesday: "05:00-18:00"
 *                   sunday: "05:00-20:00"
 *                 description: "Giờ mở cửa theo từng ngày"
 *               contact_info:
 *                 type: object
 *                 example:
 *                   phone: "028-3822-0477"
 *                   email: "contact@example.com"
 *                   website: "https://example.com"
 *                 description: "Thông tin liên hệ"
 *     responses:
 *       201:
 *         description: Tạo địa điểm thành công
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SiteResponse'
 *       400:
 *         description: Dữ liệu không hợp lệ
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       401:
 *         description: Chưa đăng nhập
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       403:
 *         description: Không có quyền admin
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
