#include "imgproc.h"

int get_interpolation_equation_coefficient(Point2D32f *input_pos, Point2D32f *out_pos, int point_cnt, int order, int order_cnt, 
										  double **coff_x, double **coff_y, double *bx, double *by)
{
	if (order > 2)
		return 0;

	int i, j, k;
	double *x = new double[point_cnt];
	double *y = new double[point_cnt];
	double *x0 = new double[point_cnt];
	double *y0 = new double[point_cnt];
	double calc_coff[100], multi_val;
	for (i = 0; i < point_cnt; i ++)
	{
		x[i] = input_pos[i].x;
		y[i] = input_pos[i].y;
		x0[i] = out_pos[i].x;
		y0[i] = out_pos[i].y;
	}
	if (order == 1)
	{
		if (order_cnt != 4)
		{
			delete[] x;
			delete[] y;
			delete[] x0;
			delete[] y0;
			return 0;
		}
		for (j = 0; j < order_cnt; j ++)
		{
			for (k = 0; k < point_cnt; k ++)
			{
				if (j == 0)
					multi_val = 1;
				else if (j == 1)
					multi_val = x[k];
				else if (j == 2)
					multi_val = y[k];
				else if (j == 3)
					multi_val = x[k] * y[k];

				calc_coff[0] = 1;
				calc_coff[1] = x[k];
				calc_coff[2] = y[k];
				calc_coff[3] = x[k] * y[k];
				for (i = 0; i < order_cnt; i ++)
				{
					coff_x[j][i] +=  calc_coff[i] * multi_val;
					coff_y[j][i] +=  calc_coff[i] * multi_val;
				}
				bx[j] += x0[k] * multi_val ;
				by[j] += y0[k] * multi_val;
			}
		}
	}
	else if (order == 2)
	{
		if (order_cnt != 6)
		{
			delete[] x;
			delete[] y;
			delete[] x0;
			delete[] y0;
			return 0;
		}
		for (j = 0; j < order_cnt; j ++)
		{
			for (k = 0; k < point_cnt; k ++)
			{
				if (j == 0)
					multi_val = 1;
				else if (j == 1)
					multi_val = x[k];
				else if (j == 2)
					multi_val = y[k];
				else if (j == 3)
					multi_val = x[k] * y[k];
				else if (j == 4)
					multi_val = x[k] * x[k];
				else if (j == 5)
					multi_val = y[k] * y[k];

				calc_coff[0] = 1;
				calc_coff[1] = x[k];
				calc_coff[2] = y[k];
				calc_coff[3] = x[k] * y[k];
				calc_coff[4] = x[k] * x[k];
				calc_coff[5] = y[k] * y[k];

				for (i = 0; i < order_cnt; i ++)
				{
					coff_x[j][i] +=  calc_coff[i] * multi_val;
					coff_y[j][i] +=  calc_coff[i] * multi_val;
				}
				bx[j] += x0[k] * multi_val ;
				by[j] += y0[k] * multi_val;
			}
		}
	}
	else if (order == 3)
	{
		if (order_cnt != 10)
		{
			delete[] x;
			delete[] y;
			delete[] x0;
			delete[] y0;
			return 0;
		}
		for (j = 0; j < order_cnt; j ++)
		{
			for (k = 0; k < point_cnt; k ++)
			{
				if (j == 0)
					multi_val = 1;
				else if (j == 1)
					multi_val = x[k];
				else if (j == 2)
					multi_val = y[k];
				else if (j == 3)
					multi_val = x[k] * y[k];
				else if (j == 4)
					multi_val = x[k] * x[k];
				else if (j == 5)
					multi_val = y[k] * y[k];
				else if (j == 6)
					multi_val = x[k] * x[k] * x[k];
				else if (j == 7)
					multi_val = x[k] * x[k] * y[k];
				else if (j == 8)
					multi_val = x[k] * y[k] * y[k];
				else if (j == 9)
					multi_val = y[k] * y[k] * y[k];

				calc_coff[0] = 1;
				calc_coff[1] = x[k];
				calc_coff[2] = y[k];
				calc_coff[3] = x[k] * y[k];
				calc_coff[4] = x[k] * x[k];
				calc_coff[5] = y[k] * y[k];
				calc_coff[6] = x[k] * x[k] * x[k];
				calc_coff[7] = x[k] * x[k] * y[k];
				calc_coff[8] = x[k] * y[k] * y[k];
				calc_coff[9] = y[k] * y[k] * y[k];

				for (i = 0; i < order_cnt; i ++)
				{
					coff_x[j][i] +=  calc_coff[i] * multi_val;
					coff_y[j][i] +=  calc_coff[i] * multi_val;
				}
				bx[j] += x0[k] * multi_val ;
				by[j] += y0[k] * multi_val;
			}
		}
	}	

	return 1;
}

int calculate_dst_coordinate(Point2D32f input_pos, Point2D32f *out_pos, int order_cnt, float *solution_x, float *solution_y)
{
	if (solution_x == NULL || solution_y == NULL || order_cnt > 10)
		return 0;

	int i;
	Point2D32f tmp_pos2 = {0,};
	float val[100] = {0,};

	val[0] = 1;
	val[1] = input_pos.x;
	val[2] = input_pos.y;
	val[3] = input_pos.x * input_pos.y;
	val[4] = input_pos.x * input_pos.x;
	val[5] = input_pos.y * input_pos.y ;
	val[6] = input_pos.x * input_pos.x * input_pos.x ;
	val[7] = input_pos.x * input_pos.x * input_pos.y ;
	val[8] = input_pos.x * input_pos.y * input_pos.y ;
	val[9] = input_pos.y * input_pos.y * input_pos.y ;

	for(i = 0; i < 10; i ++)
	{
		tmp_pos2.x += val[i] * solution_x[i];
		tmp_pos2.y += val[i] * solution_y[i];
	}

	*out_pos = tmp_pos2;

	return 1;
}

double cubic_interpolation(double v1, double v2, double v3, double v4, double d) 
{
	double v, p1, p2, p3, p4;

	p1 = v2;
	p2 = -v1 + v3;
	p3 = 2*(v1 - v2) + v3 - v4;
	p4 = -v1 + v2 - v3 + v4;

	v = p1 + d*(p2 + d*(p3 + d*p4));

	return v;
}

void get_pixelvalue_by_cubic(BYTE *src_data, SizeInfo img_size, Point2D32f scan_pos, BYTE *img_val, int nc, int nk)
{
	int w = img_size.width;
	int h = img_size.height;

	int x1, x2, x3, x4, y1, y2, y3, y4;
	double v1, v2, v3, v4, v;
	double rx, ry, p, q;

	rx = (double)scan_pos.x;
	ry = (double)scan_pos.y;

	x2 = (int)rx;
	x1 = x2 - 1; if( x1 <  0 ) x1 = 0;
	x3 = x2 + 1; if( x3 >= w ) x3 = w - 1;
	x4 = x2 + 2; if( x4 >= w ) x4 = w - 1;
	p  = rx - x2;

	y2 = (int)ry;
	y1 = y2 - 1; if( y1 <  0 ) y1 = 0;
	y3 = y2 + 1; if( y3 >= h ) y3 = h - 1;
	y4 = y2 + 2; if( y4 >= h ) y4 = h - 1;
	q  = ry - y2;

	v1 = cubic_interpolation(src_data[nc*(y1*w+x1) + nk], src_data[nc*(y1*w+x2) + nk], src_data[nc*(y1*w+x3) + nk], src_data[nc*(y1*w+x4) + nk], p);
	v2 = cubic_interpolation(src_data[nc*(y2*w+x1) + nk], src_data[nc*(y2*w+x2) + nk], src_data[nc*(y2*w+x3) + nk], src_data[nc*(y2*w+x4) + nk], p);
	v3 = cubic_interpolation(src_data[nc*(y3*w+x1) + nk], src_data[nc*(y3*w+x2) + nk], src_data[nc*(y3*w+x3) + nk], src_data[nc*(y3*w+x4) + nk], p);
	v4 = cubic_interpolation(src_data[nc*(y4*w+x1) + nk], src_data[nc*(y4*w+x2) + nk], src_data[nc*(y4*w+x3) + nk], src_data[nc*(y4*w+x4) + nk], p);

	v  = cubic_interpolation(v1, v2, v3, v4, q);

	*img_val = (BYTE)limit(v);

}

int get_pixelvalue_by_linear(BYTE *src_data, SizeInfo img_size, Point2D32f scan_pos, BYTE *img_val)
{
	int x, y;
	int width = img_size.width;
	int height = img_size.height;
	//float average;
	x = (int)scan_pos.x;
	y = (int)scan_pos.y;
	if (x < 2)
		x = 2;
	else if (x > width - 2)
		x = width - 2;

	if (y < 2)
		y = 1;
	else if (y > height - 2)
		y = height - 2;

	float q[32][32] = {0,};
	q[0][0] = (float)src_data[y * width + x];
	q[0][1] = (float)src_data[(y + 1) * width + x];
	q[1][1] = (float)src_data[(y + 1) * width + x + 1];
	q[1][0] = (float)src_data[y * width + x + 1];
	float dx = scan_pos.x - x;
	float dy = scan_pos.y - y;
	float val = q[0][0] * (1 - dx) * (1 - dy) + q[0][1] * dx * (1 - dy) + q[1][0] * dy * (1 - dx) + q[1][1] * dx * dy;

	*img_val = (BYTE)limit(Round(val));

	return 1;
}

int calculate_linear_equation(IPOINT *pData, int nPointCnt, double *a, double *b)
{
	double sum_x2 = 0, sum_x1 = 0, sum_xy = 0, sum_y1 = 0;
	int i;
	for (i = 0; i<nPointCnt; i++)
	{
		sum_x2 += pData[i].x * pData[i].x * 1.0;
		sum_x1 += pData[i].x *1.0;
		sum_xy += pData[i].x * pData[i].y*1.0;
		sum_y1 += pData[i].y*1.0;
	}

	double matrix_val1 = nPointCnt*sum_x2 - sum_x1*sum_x1;
	if (matrix_val1 < 1e-6)
		return 0;
	double matrix_val2 = nPointCnt*sum_xy - sum_x1*sum_y1;
	double matrix_val3 = sum_x2*sum_y1 - sum_x1*sum_xy;

	*a = matrix_val2 / matrix_val1;
	*b = matrix_val3 / matrix_val1;

	return 1;
}
